const std = @import("std");
const Context = @import("lib/context.zig");
const Address = @import("lib/address.zig").Address;
const AddressState = @import("lib/address_state.zig");
const Block = @import("lib/block.zig");
const Chain = @import("lib/chain.zig");
const ChainState = @import("lib/chain_state.zig");
const RPCClient = @import("lib/utils/rpc//rpc_client.zig");
const Hex = @import("lib/utils/hex.zig");

const Self = @This();

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

pub fn init(allocator: std.mem.Allocator, initializer: EVMInitializer) Self {
    return .{
        .allocator = allocator,
        .context = initializer.context,
        .fork_url = null,
        .fork_block = 0,
    };
}

pub fn fork_init(allocator: std.mem.Allocator, initializer: EVMForkInitializer) !Self {
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

pub fn deinit(self: *Self) void {
    if (self.rpc_client) |client| {
        client.deinit();
    }
}

pub fn initContext(self: *Self) !void {
    var client = self.rpc_client.?;
    const address = self.context.address;
    const code = try client.getCode(address);
    if (self.context.state.address_states.get(address)) |address_state| {
        address_state.code = code;
        return;
    }
    var address_state = AddressState.init(
        self.allocator,
        try client.getBalance(address),
        try client.getTransactionCount(address),
        code,
    );
    try self.context.state.address_states.put(address, &address_state);
}

pub fn run(self: *Self, run_params: EVMRunParams) ![]u8 {
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

test "Simple addition" {
    const code_string = "0x60016004015f5260205ff3";
    const code = try std.testing.allocator.alloc(u8, 11);
    defer std.testing.allocator.free(code);
    Hex.parseStaticBuffer(code_string, 11, code);
    var context = Context.initEmpty(std.testing.allocator);
    var address_state = AddressState.init(std.testing.allocator, 0, 0, code);
    try context.state.address_states.put(1, &address_state);
    var evm = Self.init(std.testing.allocator, .{
        .context = &context,
    });
    const return_data = try evm.run(.{});
    try std.testing.expectEqual(32, return_data.len);
}
