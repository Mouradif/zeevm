const std = @import("std");

const Block = @import("../types/block.zig");
const Chain = @import("../types/chain.zig");
const Hex = @import("../utils/hex.zig");
const ChainState = @import("../types/chain_state.zig").ChainState;

const Context = @import("context.zig");
const AddressState = @import("address_state.zig");
const RPCClient = @import("../utils/rpc/rpc_client.zig");

const EVM = @This();

const EVMInitializer = struct {
    context: *Context,
};

const EVMForkInitializer = struct {
    fork_url: []const u8,
    fork_block: u64 = 0,
};

const EVMRunParams = struct {
    caller: u160 = 2,
    origin: u160 = 2,
    address: u160 = 1,
    call_value: u256 = 0,
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
    if (self.context.state.get(address)) |address_state| {
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
    try self.context.state.put(address, &address_state);
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

    const address_state = self.context.state.get(self.context.address).?;
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
        .state = ChainState.init(std.testing.allocator),
    });
    var address_state = AddressState.init(std.testing.allocator, .{ .code = code });
    try context.state.put(1, &address_state);
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

test "EVM: Control Flow" {
    try testReturnsOneWord("5f5b60010180600a116001575f5260205ff3", 10, 305);
}

test "EVM: Solidity loop" {
    try testReturnsOneWord("6080604052348015600e575f80fd5b505f3660605f805b600a8110156036578082602891906099565b915080806001019150506016565b50806040516020016046919060d2565b604051602081830303815290604052915050915050805190602001f35b5f819050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f60a1826063565b915060aa836063565b925082820190508082111560bf5760be606c565b5b92915050565b60cc816063565b82525050565b5f60208201905060e35f83018460c5565b9291505056fea2646970667358221220fa8b7f4c3b6dcd9b6d4243a10fdab58bb71c6bfb5a5928bb5bae3495b6724f5564736f6c634300081a0033", 45, 2808);
}
