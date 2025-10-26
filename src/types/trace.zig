const std = @import("std");

const StringList = std.array_list.Managed([]u8);

allocator: std.mem.Allocator,
entries: StringList,

const Trace = @This();

pub fn init(allocator: std.mem.Allocator) Trace {
    return .{
        .allocator = allocator,
        .entries = StringList.init(allocator),
    };
}

pub fn deinit(self: *Trace) void {
    for (self.entries.items) |entry| {
        self.allocator.free(entry);
    }
    self.entries.deinit();
}

pub fn push(self: *Trace, entry: []u8) !void {
    try self.entries.addOne(entry);
}
