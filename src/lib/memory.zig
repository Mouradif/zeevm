const std = @import("std");
const MemoryError = @import("memory_error.zig").MemoryError;

const ByteArray = std.ArrayList(u8);

const MAX_COST = 30_000_000;

allocator: std.mem.Allocator,
buffer: ByteArray,

const Memory = @This();

pub fn init(allocator: std.mem.Allocator) Memory {
    return Memory{
        .allocator = allocator,
        .buffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *Memory) void {
    self.buffer.deinit();
}

pub fn expand(self: *Memory) !void {
    _ = try self.buffer.appendNTimes(0, 32);
    if (self.cost() > MAX_COST) {
        return MemoryError.LimitReached;
    }
}

pub fn expandToOffset(self: *Memory, offset: u256, increment: u8) !void {
    while (self.buffer.items.len < offset + increment) {
        try self.expand();
    }
}

pub fn store(self: *Memory, offset: u256, n: u256) !void {
    const ofs: usize = @truncate(offset);
    try expandToOffset(self, offset, 32);
    const bytes: [32]u8 = @bitCast(@byteSwap(n));
    try self.buffer.replaceRange(ofs, 32, &bytes);
}

pub fn storeByte(self: *Memory, offset: u256, n: u8) !void {
    const ofs: usize = @truncate(offset);
    try expandToOffset(self, offset, 1);
    const bytes: [1]u8 = .{n};
    try self.buffer.replaceRange(ofs, 1, &bytes);
}

pub fn load(self: *Memory, offset: u256) !u256 {
    const ofs: usize = @truncate(offset);
    try expandToOffset(self, offset, 32);
    const word: *[32]u8 = @ptrCast(self.buffer.items[ofs .. ofs + 32]);
    const output: u256 = @bitCast(word.*);
    return @byteSwap(output);
}

pub fn read(self: *Memory, offset: u256, len: u256) ![]u8 {
    while (self.buffer.items.len < offset + len) {
        try self.expand();
    }
    const length: usize = @truncate(len);
    const ofs: usize = @truncate(offset);
    const data = try self.allocator.alloc(u8, length);
    @memcpy(data, self.buffer.items[ofs .. ofs + length]);
    return data;
}

pub fn cost(self: *Memory) u64 {
    const len = self.buffer.items.len;
    const words = @divFloor(len + 31, 32);

    return (@divFloor(std.math.pow(u64, words, 2), 512) + (3 * words));
}

pub fn debugPrint(self: *Memory) !void {
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
