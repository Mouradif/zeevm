const std = @import("std");
const Address = @import("address.zig").Address;
const AddressState = @import("address_state.zig");
const RPCClient = @import("utils/rpc/rpc_client.zig");
const Block = @import("block.zig");
const Chain = @import("chain.zig");
const ChainState = @import("chain_state.zig");
const Stack = @import("stack.zig");
const Memory = @import("memory.zig");
const ContextStatus = @import("context_status.zig").ContextStatus;
const ContextError = @import("context_error.zig").ContextError;
const OpCode = @import("opcode.zig").OpCode;
const Interpreter = @import("interpreter.zig");

const ContextInitializer = struct {
    chain: ?Chain = null,
    block: ?Block = null,
    rpc_client: ?*RPCClient = null,
    state: ChainState,
    gas: u64,
    address: Address = 0,
    caller: Address = 0,
    origin: Address = 0,
    call_value: u256 = 0,
    call_data: []const u8,
};

const Self = @This();
const Context = Self;

allocator: std.mem.Allocator,
chain: *const Chain,
block: *const Block,
rpc_client: ?*RPCClient,
state: *ChainState,
memory: Memory,
gas: u64,
address: Address,
caller: Address,
origin: Address,
call_value: u256,
call_data: []const u8,
return_data: []u8 = undefined,
status: ContextStatus = .Continue,
stack: Stack = Stack{},
parent: ?*Self = null,
child: ?*Self = null,
code: ?[]const u8 = null,
program_counter: u32 = 0,
memory_expansion_cost: u64 = 0,

pub fn init(allocator: std.mem.Allocator, initializer: ContextInitializer) Self {
    var chain = if (initializer.chain) |s| s else Chain{};
    var block = if (initializer.block) |b| b else Block{};
    var state = initializer.state;
    return .{
        .allocator = allocator,
        .chain = &chain,
        .block = &block,
        .rpc_client = initializer.rpc_client,
        .state = &state,
        .gas = initializer.gas,
        .address = initializer.address,
        .caller = initializer.caller,
        .origin = initializer.origin,
        .call_value = initializer.call_value,
        .call_data = initializer.call_data,
        .memory = Memory.init(allocator),
    };
}

pub fn initEmpty(allocator: std.mem.Allocator) Self {
    var chain = Chain{};
    var block = Block{};
    var state = ChainState.init(allocator);
    return .{
        .allocator = allocator,
        .chain = &chain,
        .block = &block,
        .rpc_client = null,
        .state = &state,
        .gas = 100_000,
        .address = 1,
        .caller = 2,
        .origin = 2,
        .call_value = 100,
        .call_data = "",
        .memory = Memory.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.memory.deinit();
}

pub fn spawn(self: *Self, address: Address, value: u256, data: []u8, gas: u64, is_delegate: bool) !*Self {
    try self.spendGas(gas);
    var sub_context = Self.init(self.allocator, .{
        .block = self.block.*,
        .state = self.state.*,
        .chain = self.chain.*,
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
    return &sub_context;
}

pub fn loadCode(self: *Self) void {
    self.code = self.state.getCode(self.address);
}

pub fn spendGas(self: *Self, amount: u64) !void {
    if (self.gas < amount) {
        return ContextError.OutOfGas;
    }
    self.gas -= amount;
}

pub fn startTransaction(self: *Self) !void {
    try self.spendGas(21000);
}

pub fn runNextOperation(self: *Self) !void {
    if (self.program_counter == 0) {
        self.startTransaction() catch {
            self.status = .OutOfGas;
            return;
        };
        self.loadCode();
    }

    if (self.program_counter >= self.code.?.len) {
        self.status = if (self.program_counter == 0) .Stop else .Panic;
        return;
    }

    const byte: u8 = self.code.?[self.program_counter];
    const opcode: OpCode = @enumFromInt(byte);
    try Interpreter.run(self, opcode);
    if (self.memory_expansion_cost > 0) {
        try self.spendGas(self.memory_expansion_cost);
        self.memory_expansion_cost = 0;
    }
}

pub fn advanceProgramCounter(self: *Self, n: u32) void {
    self.program_counter += n;
}

pub fn loadAddress(self: *Self, address: Address) !*AddressState {
    if (self.state.address_states.get(address)) |address_state| {
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
        var address_state = AddressState.init(self.state.allocator, balance, nonce, code);
        address_state.is_warm = true;
        try self.state.address_states.put(address, &address_state);
        return self.state.address_states.get(address).?;
    }
}

pub fn loadStorageSlot(self: *Self, slot: u256) !u256 {
    const address_state = self.state.address_states.get(self.address).?;
    const is_warm = address_state.storage_accesslist.contains(slot);
    if (!is_warm) {
        try self.spendGas(2000);
    }
    return address_state.sLoad(slot);
}

pub fn writeStorageSlot(self: *Self, slot: u256, value: u256) !void {
    const address_state = self.state.address_states.get(self.address).?;
    const is_warm = address_state.storage_accesslist.contains(slot);
    if (!is_warm) {
        try self.spendGas(2100);
    }
    try address_state.sStore(slot, value);
}

pub fn blockHash(self: *Self, block_number: u256) u256 {
    _ = block_number;
    return self.block.hash;
}

pub fn push(self: *Self, n: u6) !void {
    try self.spendGas(3);
    var bytes: [32]u8 = @bitCast(@as(u256, 0));
    for (0..n) |i| {
        const index = self.program_counter + (n - i);
        if (index > self.code.?.len) {
            self.status = .Panic;
            return;
        }
        bytes[i] = self.code.?[index];
    }

    const word: u256 = @bitCast(bytes);
    try self.stack.push(word);

    self.program_counter += n + 1;
}

pub fn dup(self: *Self, n: u5) !void {
    try self.spendGas(3);
    try self.stack.dup(n);
    self.program_counter += 1;
}

pub fn swap(self: *Self, n: u5) !void {
    try self.spendGas(3);
    try self.stack.swap(n);
    self.program_counter += 1;
}

test "Spawn" {
    var block = Block{
        .timestamp = 666,
    };
    block.number = 32;
    var state = ChainState.init(std.testing.allocator);
    defer state.deinit();
    var context = Context.init(std.testing.allocator, .{
        .block = block,
        .state = state,
        .gas = 100,
        .call_data = "",
    });
    defer context.deinit();
    const sub_context = try context.spawn(1, 0, "", 10, false);
    try std.testing.expectEqual(context.block, sub_context.block);
    try std.testing.expectEqual(context.chain, sub_context.chain);
    try std.testing.expectEqual(context.state, sub_context.state);
    try std.testing.expectEqual(context.address, sub_context.caller);
    try std.testing.expectEqual(ContextStatus.Spawn, context.status);
    try std.testing.expectEqual(ContextStatus.Continue, sub_context.status);
}

test "Gas" {
    var state = ChainState.init(std.testing.allocator);
    defer state.deinit();
    var context = Context.init(std.testing.allocator, .{
        .gas = 1000,
        .state = state,
        .call_data = "",
    });
    defer context.deinit();

    try context.memory.store(12, 0xff);
    try std.testing.expectEqual(1000, context.gas);
}
