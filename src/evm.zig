const std = @import("std");
const Context = @import("lib/context.zig");
const Address = @import("lib/address.zig").Address;
const AddressState = @import("lib/address_state.zig");
const Block = @import("lib/block.zig");
const Chain = @import("lib/chain.zig");
const ChainState = @import("lib/chain_state.zig");
const RPCClient = @import("lib/utils/rpc//rpc_client.zig");

const Self = @This();

const EVMInitializer = struct {
    context: *Context,
};

const EVMForkInitializer = struct {
    fork_url: []const u8,
    fork_block: u64 = 0,
};

const EVMRunParams = struct {
    caller: Address = 0,
    origin: Address = 0,
    address: Address = 0,
    call_value: u256 = 0,
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
    const client = try RPCClient.init(allocator, initializer.fork_url);
    const block = try allocator.create(Block);
    block.number = if (initializer.block_number == 0) try client.blockNumber() else initializer.block_number;
    const chain = try allocator.create(Chain);
    chain.id = try client.chainId();
    const chain_state = ChainState.init(allocator);
    const context = Context.init(allocator, .{
        .block = block,
        .chain = chain,
        .rpc_client = client,
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
    }
}

pub fn deinit(self: *Self) void {
    if (self.rpc_client) |client| {
        client.deinit();
    }
}

pub fn initContext(self: *Self) !void {
    const client = self.rpc_client.?;
    const address = self.context.address;
    const code = client.getCode(address);
    if (self.context.state.address_states.get(address)) |address_state| {
        address_state.code = code;
        return;
    }
    const address_state = AddressState.init(
        self.allocator,
        try client.getBalance(address),
        try client.getTransactionCount(address),
        code,
    );
    self.context.state.address_states.put(address, address_state);
}

pub fn run(self: *Self, run_params: EVMRunParams) ![]u8 {
    self.context.address = run_params.address;
    self.context.caller = run_params.caller;
    self.context.origin = run_params.origin;
    self.context.call_value = run_params.call_value;
    self.context.call_data = run_params.call_data;
    const address_state = self.state.address_states.get(self.context.address);
    address_state.is_warm = true;
    
    if (self.rpc_client != null) {
        self.initContext();
    }

    while(self.context.status == .Continue) {
        self.context.runNextOperation();
        if (self.context.status == .Spawn) {
            self.context = self.context.child.?;
        }
    }
    
    return self.context.return_data;
}