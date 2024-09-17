const std = @import("std");
const Stack = @import("zee_stack");

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});

    var stack = Stack{};
    try stack.push(32);
}
