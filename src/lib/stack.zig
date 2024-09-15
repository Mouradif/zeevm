const std = @import("std");
const StackError = @import("../errors/stack_error.zig").StackError;

const MAX_STACK_SIZE = 1024;
const Stack = @This();

items: [MAX_STACK_SIZE]u256 = .{0} ** 1024,
head: u16 = 0,

pub fn zeroOut(self: *Stack) void {
    for (0..self.head) |i| {
        self.items[i] = 0;
    }
    self.head = 0;
}

pub fn push(self: *Stack, n: u256) !void {
    try self.ensureCanGrowBy(1);
    self.items[self.head] = n;
    self.head += 1;
}

pub fn dup(self: *Stack, i: u8) !void {
    if (i == 0) {
        return StackError.Illegal;
    }
    try self.ensureCanGrowBy(1);
    try self.ensureHasAtLeast(i);
    try self.push(self.items[self.head - i]);
}

pub fn swap(self: *Stack, i: u8) !void {
    if (i == 0) {
        return StackError.Illegal;
    }
    if (i >= self.head) {
        return StackError.Underflow;
    }
    const index_a = self.head - 1;
    const index_b = index_a - i;
    self.items[index_a] ^= self.items[index_b];
    self.items[index_b] ^= self.items[index_a];
    self.items[index_a] ^= self.items[index_b];
}

pub fn peek(self: *Stack) u256 {
    return self.items[self.head - 1];
}

pub fn pop(self: *Stack) !u256 {
    if (self.head == 0) {
        return StackError.Underflow;
    }
    const item = self.items[self.head - 1];
    self.items[self.head - 1] = 0;
    self.head -= 1;
    return item;
}

pub fn ensureHasAtLeast(self: *Stack, n: u10) !void {
    if (n > self.head) {
        return StackError.Underflow;
    }
}

pub fn ensureCanGrowBy(self: *Stack, n: u10) !void {
    if (self.head + n >= MAX_STACK_SIZE) {
        return StackError.Overflow;
    }
}

pub fn dump(self: *Stack, allocator: std.mem.Allocator) ![]u256 {
    const stack: []u256 = try allocator.alloc(u256, self.head);
    for (stack, 0..self.head) |*item, i| {
        item.* = self.items[i];
    }
    return stack[0..self.head];
}

test "push" {
    var stack = Stack{};

    try stack.push(42);
    try stack.push(100);

    try std.testing.expectEqual(100, try stack.pop());
    try std.testing.expectEqual(42, try stack.pop());
}

test "pop" {
    var stack = Stack{};

    try stack.push(42);
    try stack.push(100);
    const tip = stack.pop();
    try std.testing.expectEqual(42, stack.peek());
    try std.testing.expectEqual(100, tip);
}

test "swap" {
    var stack = Stack{};

    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try stack.swap(2);

    try std.testing.expectEqual(1, try stack.pop());
    try std.testing.expectEqual(2, try stack.pop());
    try std.testing.expectEqual(3, try stack.pop());
}

test "dup" {
    var stack = Stack{};

    try stack.push(15);
    try stack.push(30);
    try stack.dup(1);
    try stack.dup(3);

    try std.testing.expectEqual(15, try stack.pop());
    try std.testing.expectEqual(30, try stack.pop());
    try std.testing.expectEqual(30, try stack.pop());
    try std.testing.expectEqual(15, try stack.pop());
}

test "dump" {
    var stack = Stack{};

    const allocator = std.testing.allocator;
    try stack.push(42);
    try stack.push(100);
    const out = try stack.dump(allocator);
    defer allocator.free(out);
    try std.testing.expectEqual(2, out.len);
    try std.testing.expectEqual(42, out[0]);
    try std.testing.expectEqual(100, out[1]);
}

test "push overflow" {
    var stack = Stack{};

    for (1..1024) |i| {
        try stack.push(@intCast(i));
    }

    const err = stack.push(666);
    try std.testing.expectError(StackError.Overflow, err);
    _ = try stack.pop();
    try stack.push(42);
    try std.testing.expectEqual(42, stack.peek());
}

test "dup overflow" {
    var stack = Stack{};

    for (1..1024) |i| {
        try stack.push(@intCast(i));
    }

    const err = stack.dup(1);
    try std.testing.expectError(StackError.Overflow, err);
    _ = try stack.pop();
    try stack.push(42);
    try std.testing.expectEqual(42, stack.peek());
}

test "pop underflow" {
    var stack = Stack{};

    const err = stack.pop();
    try std.testing.expectError(StackError.Underflow, err);
}

test "dup underflow" {
    var stack = Stack{};

    const err1 = stack.dup(1);
    try std.testing.expectError(StackError.Underflow, err1);
    try stack.push(42);
    try stack.dup(1);

    const err2 = stack.dup(3);
    try std.testing.expectError(StackError.Underflow, err2);
}

test "zero out" {
    var stack = Stack{};

    try stack.push(32);
    try stack.dup(1);
    try stack.push(0);
    try stack.dup(2);

    try std.testing.expectEqual(stack.head, 4);
    stack.zeroOut();

    try std.testing.expectEqual(stack.head, 0);
    for (0..4) |i| {
        try std.testing.expectEqual(stack.items[i], 0);
    }
}
