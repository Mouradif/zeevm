const std = @import("std");
const AddressState = @import("../lib/address_state.zig");

pub const ChainState = std.AutoHashMap(u160, *AddressState);
