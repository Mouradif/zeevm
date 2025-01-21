const std = @import("std");
const config = @import("config");

const ContextStatus = @import("../types/context_status.zig").ContextStatus;
const Block = @import("../types/block.zig");
const Chain = @import("../types/chain.zig");
const ContextError = @import("../errors/context_error.zig").ContextError;
const ChainState = @import("../types/chain_state.zig").ChainState;
const OpCode = @import("../types/opcode.zig").OpCode;
const AddressAccesslist = @import("../types/address_accesslist.zig").AddressAccesslist;

const AddressState = @import("address_state.zig");
const Stack = @import("stack.zig");
const Memory = @import("memory.zig");
const Interpreter = @import("interpreter.zig");
const RPCClient = @import("../utils/rpc/rpc_client.zig");
const Hash = @import("../utils//hash.zig");

const debugLogEmitter = @import("../utils/log/debug_log_emitter.zig").debugLogEmitter;

fn printU256(n: u256) void {
    const bytes: [32]u8 = @bitCast(@byteSwap(n));
    var output_started = false;
    std.debug.print(" 0x", .{});
    for (bytes) |byte| {
        if (!output_started and byte == 0) {
            continue;
        }
        std.debug.print("{x:0>2}", .{byte});
        output_started = true;
    }
    if (!output_started) {
        std.debug.print("00", .{});
    }
}

const ContextInitializer = struct {
    chain: Chain = Chain{},
    block: Block = Block{},
    rpc_client: ?*RPCClient = null,
    state: ?ChainState = null,
    gas: u64 = 30_000_000,
    address: u160 = 0,
    caller: u160 = 0,
    origin: u160 = 0,
    call_value: u256 = 0,
    call_data: []const u8 = "",
    call_result_offset: u32 = 0,
    call_result_length: u32 = 0,
};

const ContextUpdater = struct {
    chain: ?Chain = null,
    block: ?Block = null,
    rpc_client: ?*RPCClient = null,
    state: ?ChainState = null,
    gas: ?u64 = null,
    address: ?u160 = null,
    caller: ?u160 = null,
    origin: ?u160 = null,
    call_value: ?u256 = null,
    call_data: ?[]const u8 = null,
};

const Context = @This();

const LogEmitter = fn (topics: []u256, data: []u8) anyerror!void;

fn calldataCost(calldata: []const u8) u64 {
    var cost: u64 = 0;
    for (calldata) |byte| {
        cost += if (byte == 0) 4 else 16;
    }
    return cost;
}

allocator: std.mem.Allocator,
chain: Chain,
block: Block,
rpc_client: ?*RPCClient,
state: ChainState,
memory: Memory,
gas: u64,
address: u160,
caller: u160,
origin: u160,
call_value: u256,
call_data: []const u8,
return_data: ?[]u8 = null,
status: ContextStatus = .Continue,
stack: Stack = Stack{},
parent: ?*Context = null,
child: ?*Context = null,
code: []const u8 = "",
program_counter: u32 = 0,
memory_expansion_cost: u64 = 0,
log_emitter: *const LogEmitter,
address_accesslist: AddressAccesslist,
call_gas: u64 = 0,
call_result_offset: u256,
call_result_length: u256,

pub fn init(allocator: std.mem.Allocator, initializer: ContextInitializer) Context {
    return .{
        .allocator = allocator,
        .chain = initializer.chain,
        .block = initializer.block,
        .rpc_client = initializer.rpc_client,
        .state = initializer.state orelse ChainState.init(allocator),
        .gas = initializer.gas,
        .address = initializer.address,
        .caller = initializer.caller,
        .origin = initializer.origin,
        .call_value = initializer.call_value,
        .call_data = initializer.call_data,
        .memory = Memory.init(allocator),
        .log_emitter = debugLogEmitter,
        .address_accesslist = AddressAccesslist.init(allocator),
        .call_result_offset = initializer.call_result_offset,
        .call_result_length = initializer.call_result_length,
    };
}

pub fn soft_deinit(self: *Context) void {
    if (self.child != null) {
        if (self.child.?.return_data != null) {
            self.child.?.allocator.free(self.child.?.return_data.?);
        }
        self.child.?.soft_deinit();
        self.child = null;
    }
    self.memory.deinit();
}

pub fn deinit(self: *Context) void {
    self.soft_deinit();
    var it = self.address_accesslist.keyIterator();
    while (it.next()) |address_ptr| {
        if (self.state.get(address_ptr.*)) |address_state| {
            address_state.deinit();
        }
    }
    self.address_accesslist.deinit();
    self.state.deinit();
}

pub fn update(self: *Context, update_data: ContextUpdater) void {
    if (update_data.chain) | chain | {
        self.chain = chain;
    }
    if (update_data.block) | block | {
        self.block = block;
    }
    if (update_data.rpc_client) | rpc_client | {
        self.rpc_client = rpc_client;
    }
    if (update_data.state) | state | {
        self.state = state;
    }
    if (update_data.gas) | gas | {
        self.gas = gas;
    }
    if (update_data.address) | address | {
        self.address = address;
    }
    if (update_data.caller) | caller | {
        self.caller = caller;
    }
    if (update_data.origin) | origin | {
        self.origin = origin;
    }
    if (update_data.call_value) | call_value | {
        self.call_value = call_value;
    }
    if (update_data.call_data) | call_data | {
        self.call_data = call_data;
    }
}

pub fn spawn(self: *Context, address: u160, value: u256, data: []u8, gas: u64, is_delegate: bool) !void {
    self.call_gas = gas;
    var sub_context = Context.init(self.allocator, .{
        .block = self.block,
        .state = self.state,
        .chain = self.chain,
        .gas = gas,
        .address = address,
        .caller = if (is_delegate) self.caller else self.address,
        .origin = self.origin,
        .call_value = value,
        .call_data = data,
    });
    sub_context.parent = self;
    self.child = &sub_context;
    self.status = .Spawn;
}

pub fn loadCode(self: *Context) void {
    self.code = self.getCode(self.address);
}

pub fn spendGas(self: *Context, amount: u64) !void {
    if (self.gas < amount) {
        return ContextError.OutOfGas;
    }
    self.gas -= amount;
}

pub fn spendCalldataGas(self: *Context) !void {
    const cost = calldataCost(self.call_data);
    try self.spendGas(cost);
}

pub fn startTransaction(self: *Context) !void {
    if (self.parent == null) {
        try self.spendGas(21000);
    }
}

pub fn runNextOperation(self: *Context) !void {
    if (self.program_counter == 0) {
        self.startTransaction() catch {
            self.status = .OutOfGas;
            return;
        };
        self.loadCode();
    }

    if (self.program_counter >= self.code.len) {
        std.debug.print("No operation found at PC {d}\n", .{self.program_counter});
        self.status = if (self.program_counter == 0) .Stop else .Panic;
        return;
    }

    const gas_start = self.gas;
    const byte: u8 = self.code[self.program_counter];
    const pc = self.program_counter;
    try Interpreter.runTable[byte](self);

    if (self.memory_expansion_cost > 0) {
        try self.spendGas(self.memory_expansion_cost);
        self.memory_expansion_cost = 0;
    }
    const gas_used = gas_start - self.gas;
    if (comptime config.trace) {
        const opcode: OpCode = OpCode.from(byte);
        opcode.print(pc);
        if (opcode.isPush()) {
            printU256(self.stack.peek().?.*);
        }
        if (comptime config.gas) {
            std.debug.print(" ({d})\n", .{gas_used});
        } else {
            std.debug.print("\n", .{});
        }
    }
    self.advanceProgramCounter(1);
}

pub fn advanceProgramCounter(self: *Context, n: u32) void {
    self.program_counter += n;
}

pub fn loadAddress(self: *Context, address: u160) !*AddressState {
    if (self.state.get(address)) |address_state| {
        if (!address_state.is_warm) {
            try self.spendGas(2500);
            address_state.is_warm = true;
        }
        return address_state;
    } else {
        try self.spendGas(2500);
        var balance: u256 = undefined;
        var nonce: u256 = undefined;
        var code: []u8 = undefined;
        if (self.rpc_client) |client| {
            balance = try client.getBalance(address);
            nonce = try client.getTransactionCount(address);
            code = try client.getCode(address);
        } else {
            balance = 0;
            nonce = 0;
            code = "";
        }
        var address_state = AddressState.init(self.state.allocator, .{
            .balance = balance,
            .nonce = nonce,
            .code = code,
        });
        address_state.is_warm = true;
        try self.state.put(address, &address_state);
        return self.state.get(address).?;
    }
}

pub fn loadStorageSlot(self: *Context, slot: u256) !u256 {
    const address_state = self.state.get(self.address).?;
    const is_warm = address_state.storage_accesslist.contains(slot);
    if (!is_warm) {
        try self.spendGas(2000);
    }
    return address_state.sLoad(slot);
}

pub fn writeStorageSlot(self: *Context, slot: u256, value: u256) !void {
    const address_state = self.state.get(self.address).?;
    const is_warm = address_state.storage_accesslist.contains(slot);
    if (!is_warm) {
        try self.spendGas(2100);
        try address_state.storage_accesslist.put(slot, {});
    }
    const current_value = try address_state.sLoad(slot);
    if (current_value == 0 and value != 0) {
        try self.spendGas(19900);
    }
    try address_state.sStore(slot, value);
}

pub fn blockHash(self: *Context, block_number: u256) u256 {
    _ = block_number;
    return self.block.hash;
}

pub fn push(self: *Context, n: u6) !void {
    try self.spendGas(3);
    var bytes: [32]u8 = @bitCast(@as(u256, 0));
    for (0..n) |i| {
        const index = self.program_counter + (n - i);
        if (index > self.code.len) {
            self.status = .Panic;
            return;
        }
        bytes[i] = self.code[index];
    }

    const word: u256 = @bitCast(bytes);
    try self.stack.push(word);

    self.advanceProgramCounter(n);
}

pub fn dup(self: *Context, n: u5) !void {
    try self.spendGas(3);
    try self.stack.dup(n);
}

pub fn swap(self: *Context, n: u5) !void {
    try self.spendGas(3);
    try self.stack.swap(n);
}

pub fn ensureValidJumpDestination(self: *Context) !void {
    const opbyte = self.code[self.program_counter];
    const opcode = OpCode.from(opbyte);
    if (opcode != .JUMPDEST) {
        self.status = .Panic;
        return error.InvalidJumpDestination;
    }
    self.program_counter -= 1;
}

pub fn emitLog(self: *Context, topics: []u256, data: []u8) !void {
    try self.log_emitter(topics, data);
}

pub fn getCode(self: *const Context, address: u160) []const u8 {
    if (self.state.get(address)) |state| {
        return state.code orelse "";
    }
    return "";
}

pub fn codeHash(self: *Context, address: u160) u256 {
    const code = self.getCode(address);
    return Hash.keccak256(code);
}

test "Context: Spawn" {
    var block = Block{
        .timestamp = 666,
    };
    block.number = 32;
    var context = Context.init(std.testing.allocator, .{
        .block = block,
        .state = ChainState.init(std.testing.allocator),
        .gas = 100,
        .call_data = "",
    });
    defer context.deinit();
    try context.spawn(1, 0, "", 10, false);
    try std.testing.expectEqual(context.block.number, context.child.?.block.number);
    try std.testing.expectEqual(context.block.base_fee, context.child.?.block.base_fee);
    try std.testing.expectEqual(context.block.timestamp, context.child.?.block.timestamp);
    try std.testing.expectEqual(context.chain, context.child.?.chain);
    try std.testing.expectEqual(context.state, context.child.?.state);
    try std.testing.expectEqual(context.address, context.child.?.caller);
    try std.testing.expectEqual(ContextStatus.Spawn, context.status);
    try std.testing.expectEqual(ContextStatus.Continue, context.child.?.status);
}

test "Context: Gas" {
    const state = ChainState.init(std.testing.allocator);
    var context = Context.init(std.testing.allocator, .{
        .gas = 1000,
        .state = state,
        .call_data = "",
    });
    defer context.deinit();

    try context.memory.store(12, 0xff);
    try std.testing.expectEqual(1000, context.gas);
}
