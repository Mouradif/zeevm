const std = @import("std");

pub fn debugLogEmitter(topics: []u256, data: []u8) anyerror!void {
    std.debug.print("LOG(\n", .{});
    for (topics) |topic| {
        std.debug.print("\t0x{x:0>64},\n", .{topic});
    }
    std.debug.print(") -> 0x", .{});
    for (data) |byte| {
        std.debug.print("{x:0>2}", .{byte});
    }
    std.debug.print("\n", .{});
}
