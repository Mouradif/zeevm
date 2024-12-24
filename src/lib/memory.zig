const std = @import("std");

const MemoryError = @import("../errors/memory_error.zig").MemoryError;
const ByteArray = @import("../types/byte_array.zig").ByteArray;

const MAX_COST = 30_000_000_000;

allocator: std.mem.Allocator,
buffer: ByteArray,

const Memory = @This();

pub fn init(allocator: std.mem.Allocator) Memory {
    return Memory{
        .allocator = allocator,
        .buffer = ByteArray.init(allocator),
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

pub fn expandToOffset(self: *Memory, offset: u256, increment: u256) !void {
    while (self.buffer.items.len < offset + increment) {
        try self.expand();
    }
}

pub fn store(self: *Memory, offset: u256, n: u256) !void {
    const start: usize = @truncate(offset);
    try expandToOffset(self, offset, 32);
    const bytes: [32]u8 = @bitCast(@byteSwap(n));
    try self.buffer.replaceRange(start, 32, &bytes);
}

pub fn storeByte(self: *Memory, offset: u256, n: u8) !void {
    const start: usize = @truncate(offset);
    try expandToOffset(self, offset, 1);
    const bytes: [1]u8 = .{n};
    try self.buffer.replaceRange(start, 1, &bytes);
}

pub fn load(self: *Memory, offset: u256) !u256 {
    const start: usize = @truncate(offset);
    try expandToOffset(self, offset, 32);
    const word: *[32]u8 = @ptrCast(self.buffer.items[start .. start + 32]);
    const output: u256 = @bitCast(word.*);
    return @byteSwap(output);
}

pub fn apply(self: *Memory, data: ?[]u8, offset: u256, len: u256) !void {
    try self.expandToOffset(offset, len);
    const start: usize = @truncate(offset);
    const length: usize = @truncate(len);
    const copy_length = if (data == null) 0 else @min(len, data.?.len);
    if (copy_length > 0) {
        @memcpy(self.buffer.items[start..start + copy_length], data.?[0..copy_length]);
    }
    if (len > copy_length) {
        @memset(self.buffer.items[start + copy_length..start + length], 0);
    }
}

pub fn copy_zerofill(self: *Memory, offset: u256, len: u256) ![]u8 {
    const start: usize = @truncate(offset);
    const length: usize = @truncate(len);
    const data = try self.allocator.alloc(u8, length);
    const current_size = self.buffer.items.len;
    const copy_length = if (start >= current_size) 0 else @min(current_size - offset, length);
    @memcpy(data[0..copy_length], self.buffer.items[start..start + copy_length]);
    @memset(data[copy_length..], 0);
    return data;
}

pub fn expand_and_copy(self: *Memory, offset: u256, len: u256) ![]u8 {
    while (self.buffer.items.len < offset + len) {
        try self.expand();
    }
    const start: usize = @truncate(offset);
    const length: usize = @truncate(len);
    const data = try self.allocator.alloc(u8, length);
    @memcpy(data, self.buffer.items[start .. start + length]);
    return data;
}

pub fn read(self: *Memory, offset: u256, len: u256) ![]u8 {
    while (self.buffer.items.len < offset + len) {
        try self.expand();
    }
    const length: usize = @truncate(len);
    const start: usize = @truncate(offset);
    return self.buffer.items[start .. start + length];
}

pub fn cost(self: *Memory) u64 {
    const len = self.buffer.items.len;
    const words = @divTrunc(len + 31, 32);

    return (@divTrunc(std.math.pow(u64, words, 2), 512) + (3 * words));
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
