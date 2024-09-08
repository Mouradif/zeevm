const std = @import("std");

pub fn RPCParsedResponse(T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        parsed: std.json.Parsed(T),
        buffer: []u8,

        const Self = @This();

        pub fn deinit(self: *Self) void {
            self.parsed.deinit();
            self.allocator.free(self.buffer);
        }
    };
}
