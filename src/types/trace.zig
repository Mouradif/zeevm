const std = @import("std");

allocator: std.mem.Allocator,
entries: std.ArrayList([]u8),

const Trace = @This();

pub fn init(allocator: std.mem.Allocator) Trace {
    return .{
        .allocator = allocator,
        .entries = std.ArrayList([]u8).init(allocator),
    };
}

pub fn deinit(self: *Trace) {
    for (self.entries.items) |entry| {
        self.allocator.free(entry);
    }
    self.entries.deinit();
}

pub fn push(self: *Trace, entry: []u8) !void {
    try self.entries.addOne(entry);
}
