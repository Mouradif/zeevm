const Fork = @import("fork.zig").Fork;
const ChainState = @import("chain_state.zig").ChainState;

id: u64 = 0,
fork: Fork = .Dencun,
gas_limit: u64 = 30_000_000,
