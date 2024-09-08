const std = @import("std");
const MemoryError = @import("memory_error.zig").MemoryError;

const ByteArray = std.ArrayList(u8);

const MAX_COST = 30_000_000;

allocator: std.mem.Allocator,
buffer: ByteArray,

const Self = @This();
const Memory = Self;

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .allocator = allocator,
        .buffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.buffer.deinit();
}

pub fn expand(self: *Self) !void {
    _ = try self.buffer.appendNTimes(0, 32);
    if (self.cost() > MAX_COST) {
        return MemoryError.LimitReached;
    }
}

pub fn expandToOffset(self: *Self, offset: u256, increment: u8) !void {
    while (self.buffer.items.len < offset + increment) {
        try self.expand();
    }
}

pub fn store(self: *Self, offset: u256, n: u256) !void {
    try expandToOffset(self, offset, 32);
    const bytes: [32]u8 = @bitCast(@byteSwap(n));
    try self.buffer.replaceRange(offset, 32, &bytes);
}

pub fn storeByte(self: *Self, offset: u256, n: u8) !void {
    try expandToOffset(self, offset, 1);
    const bytes: [32]u8 = @bitCast(@byteSwap(n));
    try self.buffer.replaceRange(offset, 32, &bytes);
}

pub fn load(self: *Self, offset: u256) !u256 {
    try expandToOffset(self, offset, 32);
    const word: *[32]u8 = @ptrCast(self.buffer.items[offset .. offset + 32]);
    const output: u256 = @bitCast(word.*);
    return @byteSwap(output);
}

pub fn read(self: *Self, offset: u256, len: u256) ![]u8 {
    while (self.buffer.items.len < offset + len) {
        try self.expand();
    }
    const data = self.allocator.alloc(u8, len);
    @memcpy(data, self.buffer.items[offset .. offset + len]);
    return data;
}

pub fn cost(self: *Self) u64 {
    const len = self.buffer.items.len;
    const words = @divFloor(len + 31, 32);

    return (@divFloor(std.math.pow(u64, words, 2), 512) + (3 * words));
}

pub fn debugPrint(self: *Self) !void {
    const out = std.debug;

    var i: usize = 0;
    for (self.buffer.items) |byte| {
        out.print("{x:0>2}", .{byte});
        i += 1;
        if (i == 32) {
            out.print("\n", .{});
            i = 0;
        }
    }
    out.print("\n", .{});
}

test "Expand" {
    var memory = Memory.init(std.testing.allocator);
    defer memory.deinit();
    try memory.expand();

    try std.testing.expectEqual(32, memory.buffer.items.len);
}

test "Store/Load" {
    var memory = Memory.init(std.testing.allocator);
    defer memory.deinit();

    const word = try memory.load(42);
    try std.testing.expectEqual(0, word);

    try memory.store(42, 0x106909b81e0065eca449beeb2ba7e4c092ab14f2761cfff40691fae93cef8539);
    const partial = try memory.load(64);
    try std.testing.expectEqual(0xfff40691fae93cef853900000000000000000000000000000000000000000000, partial);
}

test "Cost" {
    var memory = Memory.init(std.testing.allocator);
    defer memory.deinit();

    try std.testing.expectEqual(0, memory.cost());

    try memory.expand();
    try std.testing.expectEqual(3, memory.cost());

    try memory.store(5412, 0xff);
    try std.testing.expectEqual(570, memory.cost());
}
