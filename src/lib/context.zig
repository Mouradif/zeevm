const std = @import("std");
const Address = @import("address.zig").Address;
const AddressState = @import("address_state.zig");
const Block = @import("block.zig");
const Chain = @import("chain.zig");
const ChainState = @import("chain_state.zig");
const Stack = @import("stack.zig");
const Memory = @import("memory.zig");
const ContextStatus = @import("context_status.zig").ContextStatus;
const ContextError = @import("context_error.zig").ContextError;
const OpCode = @import("opcode.zig").OpCode;
const Interpreter = @import("interpreter.zig");
const RPCClient = @import("../utils/rpc/rpc_client.zig");

const ContextInitializer = struct {
    chain: ?Chain = null,
    block: ?Block = null,
    rpc_client: ?*RPCClient = null,
    state: *ChainState,
    gas: u64,
    address: Address = 0,
    caller: Address = 0,
    origin: Address = 0,
    call_value: u256 = 0,
    call_data: []const u8,
};

const Context = @This();

allocator: std.mem.Allocator,
chain: Chain,
block: Block,
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
parent: ?*Context = null,
child: ?*Context = null,
code: ?[]const u8 = null,
program_counter: u32 = 0,
memory_expansion_cost: u64 = 0,

pub fn init(allocator: std.mem.Allocator, initializer: ContextInitializer) Context {
    const chain = if (initializer.chain) |s| s else Chain{};
    const block = if (initializer.block) |b| b else Block{};
    return .{
        .allocator = allocator,
        .chain = chain,
        .block = block,
        .rpc_client = initializer.rpc_client,
        .state = initializer.state,
        .gas = initializer.gas,
        .address = initializer.address,
        .caller = initializer.caller,
        .origin = initializer.origin,
        .call_value = initializer.call_value,
        .call_data = initializer.call_data,
        .memory = Memory.init(allocator),
    };
}

pub fn initEmpty(allocator: std.mem.Allocator) !Context {
    var state = try ChainState.create(allocator);
    state.allocator = allocator;
    state.address_states = std.AutoHashMap(Address, *AddressState).init(allocator);
    return .{
        .allocator = allocator,
        .chain = Chain{},
        .block = Block{},
        .rpc_client = null,
        .state = state,
        .gas = 100_000,
        .address = 1,
        .caller = 2,
        .origin = 2,
        .call_value = 100,
        .call_data = "",
        .memory = Memory.init(allocator),
    };
}

pub fn deinit(self: *Context) void {
    self.memory.deinit();
    self.state.destroy();
}

pub fn spawn(self: *Context, address: Address, value: u256, data: []u8, gas: u64, is_delegate: bool) !*Context {
    try self.spendGas(gas);
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
    return &sub_context;
}

pub fn loadCode(self: *Context) void {
    self.code = self.state.getCode(self.address);
}

pub fn spendGas(self: *Context, amount: u64) !void {
    if (self.gas < amount) {
        return ContextError.OutOfGas;
    }
    self.gas -= amount;
}

pub fn startTransaction(self: *Context) !void {
    try self.spendGas(21000);
}

pub fn runNextOperation(self: *Context) !void {
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
    const opcode: OpCode = OpCode.from(byte);
    try Interpreter.run(self, opcode);
    if (self.memory_expansion_cost > 0) {
        try self.spendGas(self.memory_expansion_cost);
        self.memory_expansion_cost = 0;
    }
    self.advanceProgramCounter(1);
}

pub fn advanceProgramCounter(self: *Context, n: u32) void {
    self.program_counter += n;
}

pub fn loadAddress(self: *Context, address: Address) !*AddressState {
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
        var address_state = AddressState.init(self.state.allocator, .{
            .balance = balance,
            .nonce = nonce,
            .code = code,
        });
        address_state.is_warm = true;
        try self.state.address_states.put(address, &address_state);
        return self.state.address_states.get(address).?;
    }
}

pub fn loadStorageSlot(self: *Context, slot: u256) !u256 {
    const address_state = self.state.address_states.get(self.address).?;
    const is_warm = address_state.storage_accesslist.contains(slot);
    if (!is_warm) {
        try self.spendGas(2000);
    }
    return address_state.sLoad(slot);
}

pub fn writeStorageSlot(self: *Context, slot: u256, value: u256) !void {
    const address_state = self.state.address_states.get(self.address).?;
    const is_warm = address_state.storage_accesslist.contains(slot);
    if (!is_warm) {
        try self.spendGas(2100);
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
        if (index > self.code.?.len) {
            self.status = .Panic;
            return;
        }
        bytes[i] = self.code.?[index];
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
    const opbyte = self.code.?[self.program_counter];
    const opcode = OpCode.from(opbyte);
    switch (opcode) {
        .JUMPDEST => try self.spendGas(1),
        else => {
            self.status = .Panic;
            return error.InvalidJumpDestination;
        },
    }
}

test "Context: Spawn" {
    var block = Block{
        .timestamp = 666,
    };
    block.number = 32;
    var context = Context.init(std.testing.allocator, .{
        .block = block,
        .state = try ChainState.create(std.testing.allocator),
        .gas = 100,
        .call_data = "",
    });
    defer context.deinit();
    const sub_context = try context.spawn(1, 0, "", 10, false);
    try std.testing.expectEqual(context.block.number, sub_context.block.number);
    try std.testing.expectEqual(context.block.base_fee, sub_context.block.base_fee);
    try std.testing.expectEqual(context.block.timestamp, sub_context.block.timestamp);
    try std.testing.expectEqual(context.chain, sub_context.chain);
    try std.testing.expectEqual(context.state, sub_context.state);
    try std.testing.expectEqual(context.address, sub_context.caller);
    try std.testing.expectEqual(ContextStatus.Spawn, context.status);
    try std.testing.expectEqual(ContextStatus.Continue, sub_context.status);
}

test "Context: Gas" {
    const state = try ChainState.create(std.testing.allocator);
    var context = Context.init(std.testing.allocator, .{
        .gas = 1000,
        .state = state,
        .call_data = "",
    });
    defer context.deinit();

    try context.memory.store(12, 0xff);
    try std.testing.expectEqual(1000, context.gas);
}
