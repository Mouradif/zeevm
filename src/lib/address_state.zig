const std = @import("std");

allocator: std.mem.Allocator,
balance: u256,
nonce: u256,
code: []u8,
storage: std.AutoHashMap(u256, u256),
transient_storage: std.AutoHashMap(u256, u256),
is_warm: bool = false,
storage_accesslist: std.AutoHashMap(u256, void),

const AddressState = @This();

const AddressStateInitializer = struct {
    balance: u256 = 0,
    nonce: u256 = 0,
    code: []u8 = "",
};

pub fn init(allocator: std.mem.Allocator, initializer: AddressStateInitializer) AddressState {
    return .{
        .allocator = allocator,
        .balance = initializer.balance,
        .nonce = initializer.nonce,
        .code = initializer.code,
        .storage = std.AutoHashMap(u256, u256).init(allocator),
        .transient_storage = std.AutoHashMap(u256, u256).init(allocator),
        .storage_accesslist = std.AutoHashMap(u256, void).init(allocator),
    };
}

pub fn deinit(self: *AddressState) void {
    self.storage.deinit();
    self.transient_storage.deinit();
    self.storage_accesslist.deinit();
}

pub fn sLoad(self: *AddressState, slot: u256) !u256 {
    try self.storage_accesslist.put(slot, {});
    return self.storage.get(slot) orelse 0;
}

pub fn sStore(self: *AddressState, slot: u256, value: u256) !void {
    try self.storage_accesslist.put(slot, {});
    try self.storage.put(slot, value);
}

pub fn tLoad(self: *AddressState, slot: u256) u256 {
    return self.transient_storage.get(slot) orelse 0;
}

pub fn tStore(self: *AddressState, slot: u256, value: u256) !void {
    try self.transient_storage.put(slot, value);
}

pub fn clearTransientStorage(self: *AddressState) void {
    self.transient_storage.clearRetainingCapacity();
}

test "Address State: Storage" {
    const synon = 0x9eb3a30117810d5a36568714eb5350480942f644;

    var address_state = AddressState.init(std.testing.allocator, .{});
    defer address_state.deinit();

    try std.testing.expect(!address_state.storage_accesslist.contains(0));
    try address_state.sStore(0, synon);
    try std.testing.expect(address_state.storage_accesslist.contains(0));

    const owner = try address_state.sLoad(0);
    try std.testing.expectEqual(synon, owner);

    const empty = try address_state.sLoad(1);
    try std.testing.expectEqual(0, empty);
    try std.testing.expect(address_state.storage_accesslist.contains(1));
}
