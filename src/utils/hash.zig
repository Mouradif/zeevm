const std = @import("std");

pub fn keccak256(input: ?[]const u8) u256 {
    var hash_buffer: [32]u8 = undefined;
    std.crypto.hash.sha3.Keccak256.hash(input orelse "", &hash_buffer, .{});
    return @byteSwap(@as(u256, @bitCast(hash_buffer)));
}
