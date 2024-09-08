const std = @import("std");

allocator: std.mem.Allocator,
balance: u256,
nonce: u256,
code: []u8,
storage: std.AutoHashMap(u256, u256),
transient_storage: std.AutoHashMap(u256, u256),
is_warm: bool = false,
storage_accesslist: std.AutoHashMap(u256, void),

const Self = @This();

pub fn init(allocator: std.mem.Allocator, balance: u256, nonce: u256, code: []u8) Self {
    return .{
        .allocator = allocator,
        .balance = balance,
        .nonce = nonce,
        .code = code,
        .storage = std.AutoHashMap(u256, u256).init(allocator),
        .transient_storage = std.AutoHashMap(u256, u256).init(allocator),
        .storage_accesslist = std.AutoArrayHashMap(u256, void).init(allocator),
    };
}

pub fn sLoad(self: *Self, slot: u256) u256 {
    self.storage_accesslist.put(slot, {});
    return self.storage.get(slot) orelse 0;
}

pub fn sStore(self: *Self, slot: u256, value: u256) !void {
    self.storage_accesslist.put(slot, {});
    try self.storage.put(slot, value);
}

pub fn tLoad(self: *Self, slot: u256) u256 {
    return self.transient_storage.get(slot) orelse 0;
}

pub fn tStore(self: *Self, slot: u256, value: u256) !void {
    try self.transient_storage.put(slot, value);
}

pub fn clearTransientStorage(self: *Self) void {
    self.transient_storage.clearRetainingCapacity();
}

pub fn deinit(self: *Self) void {
    self.storage.deinit();
    self.transient_storage.deinit();
}
