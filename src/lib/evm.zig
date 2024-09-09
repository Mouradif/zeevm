const std = @import("std");
const Context = @import("context.zig");
const Address = @import("address.zig").Address;
const AddressState = @import("address_state.zig");
const Block = @import("block.zig");
const Chain = @import("chain.zig");
const ChainState = @import("chain_state.zig");
const RPCClient = @import("../utils/rpc/rpc_client.zig");
const Hex = @import("../utils/hex.zig");

const EVM = @This();

const EVMInitializer = struct {
    context: *Context,
};

const EVMForkInitializer = struct {
    fork_url: []const u8,
    fork_block: u64 = 0,
};

const EVMRunParams = struct {
    caller: Address = 2,
    origin: Address = 2,
    address: Address = 1,
    call_value: u256 = 100,
    gas: u64 = 30_000_000,
    call_data: []u8 = "",
};

allocator: std.mem.Allocator,
context: *Context,
rpc_client: ?RPCClient = null,
fork_url: ?[]const u8,
fork_block: u64,

pub fn init(allocator: std.mem.Allocator, initializer: EVMInitializer) EVM {
    return .{
        .allocator = allocator,
        .context = initializer.context,
        .fork_url = null,
        .fork_block = 0,
    };
}

pub fn fork_init(allocator: std.mem.Allocator, initializer: EVMForkInitializer) !EVM {
    var client = try RPCClient.init(allocator, initializer.fork_url);
    const block = try allocator.create(Block);
    block.number = if (initializer.block_number == 0) try client.blockNumber() else initializer.block_number;
    const chain = try allocator.create(Chain);
    chain.id = try client.chainId();
    const chain_state = ChainState.init(allocator);
    const context = Context.init(allocator, .{
        .block = block,
        .chain = chain,
        .rpc_client = &client,
        .state = chain_state,
        .gas = 0,
        .call_data = "",
    });
    return .{
        .allocator = allocator,
        .context = context,
        .rpc_client = client,
        .fork_url = initializer.fork_url,
        .fork_block = block.number,
    };
}

pub fn deinit(self: *EVM) void {
    if (self.rpc_client == null) return;

    self.rpc_client.?.deinit();
}

pub fn initContext(self: *EVM) !void {
    var client = self.rpc_client.?;
    const address = self.context.address;
    const code = try client.getCode(address);
    if (self.context.state.address_states.get(address)) |address_state| {
        address_state.code = code;
        return;
    }
    var address_state = AddressState.init(
        self.allocator,
        .{
            .balance = try client.getBalance(address),
            .nonce = try client.getTransactionCount(address),
            .code = code,
        },
    );
    try self.context.state.address_states.put(address, &address_state);
}

pub fn run(self: *EVM, run_params: EVMRunParams) ![]u8 {
    self.context.address = run_params.address;
    self.context.caller = run_params.caller;
    self.context.origin = run_params.origin;
    self.context.call_value = run_params.call_value;
    self.context.call_data = run_params.call_data;

    if (self.rpc_client != null) {
        try self.initContext();
    }

    const address_state = self.context.state.address_states.get(self.context.address).?;
    address_state.is_warm = true;

    while (self.context.status == .Continue) {
        try self.context.runNextOperation();
        if (self.context.status == .Spawn) {
            self.context = self.context.child.?;
        }
    }

    return self.context.return_data;
}

fn testReturnsOneWord(code_string: []const u8, expected_return: u256, expected_gas_usage: u64) !void {
    const code_len = code_string.len / 2;
    const code = try std.testing.allocator.alloc(u8, code_len);
    Hex.parseStaticBuffer(code_string, code_len, code);
    var context = Context.init(std.testing.allocator, .{
        .state = try ChainState.create(std.testing.allocator),
    });
    var address_state = AddressState.init(std.testing.allocator, .{ .code = code });
    try context.state.address_states.put(1, &address_state);
    var evm = EVM.init(std.testing.allocator, .{
        .context = &context,
    });
    const return_data = try evm.run(.{});
    defer {
        std.testing.allocator.free(code);
        context.deinit();
        evm.deinit();
        std.testing.allocator.free(return_data);
    }
    try std.testing.expectEqual(32, return_data.len);
    var word: [32]u8 = undefined;
    @memcpy(word[0..32], return_data);
    const result = @byteSwap(@as(u256, @bitCast(word)));
    try std.testing.expectEqual(expected_return, result);
    try std.testing.expectEqual(21000 + expected_gas_usage, 30_000_000 - context.gas);
}

test "EVM: The meaning of life" {
    try testReturnsOneWord("602a60005260206000F3", 42, 18);
}

test "EVM: Simple addition" {
    try testReturnsOneWord("60016004015f5260205ff3", 5, 22);
}

test "EVM: Arithmetics" {
    try testReturnsOneWord("60068061060061420004600a0202015f5260205ff3", 666, 46);
}
