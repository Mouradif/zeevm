const std = @import("std");

fn parseHexDigit(digit: u8) u8 {
    if (digit >= '0' and digit <= '9') {
        return digit - '0';
    }
    if (digit >= 'a' and digit <= 'f') {
        return digit + 10 - 'a';
    }
    if (digit >= 'A' and digit <= 'F') {
        return digit + 10 - 'A';
    }
    return 0;
}

fn parseHexByte(high: u8, low: u8) u8 {
    return parseHexDigit(high) << 4 + parseHexDigit(low);
}

pub fn parseStaticBuffer(input: [:0]const u8, comptime length: usize, buffer: *[length]u8) void {
    const start: usize = if (input[1] == 'x') 2 else 0;

    var i: usize = 0;
    while (i < length) : (i += 1) {
        const c1 = input[i * 2 + start];
        const c2 = input[i * 2 + start + 1];
        buffer[i] = parseHexByte(c1, c2);
    }
}

pub fn parseUint(input: [:0]const u8, T: type) T {
    const byteSize = @divFloor(@bitSizeOf(T), 8);
    var buffer: [byteSize]u8 = undefined;
    parseStaticBuffer(input, byteSize, &buffer);
    return @byteSwap(@as(T, @bitCast(buffer)));
}

test "Parse normal hex string without prefix" {
    const input = "36cc3b4eb1a6e7079cedee9f7487c8d968bfc9e30db863e533e93f6c7956bba9";
    var output: [32]u8 = undefined;
    parseStaticBuffer(input, 32, &output);

    for ("\x36\xcc\x3b\x4e\xb1\xa6\xe7\x07\x9c\xed\xee\x9f\x74\x87\xc8\xd9\x68\xbf\xc9\xe3\x0d\xb8\x63\xe5\x33\xe9\x3f\x6c\x79\x56\xbb\xa9", 0..) |byte, i| {
        try std.testing.expectEqual(byte, output[i]);
    }
}

test "Parse normal hex string with prefix" {
    const input = "0x36cc3b4eb1a6e7079cedee9f7487c8d968bfc9e30db863e533e93f6c7956bba9";
    var output: [32]u8 = undefined;
    parseStaticBuffer(input, 32, &output);

    for ("\x36\xcc\x3b\x4e\xb1\xa6\xe7\x07\x9c\xed\xee\x9f\x74\x87\xc8\xd9\x68\xbf\xc9\xe3\x0d\xb8\x63\xe5\x33\xe9\x3f\x6c\x79\x56\xbb\xa9", 0..) |byte, i| {
        try std.testing.expectEqual(byte, output[i]);
    }
}

test "Parse U256" {
    const input = "0x36cc3b4eb1a6e7079cedee9f7487c8d968bfc9e30db863e533e93f6c7956bba9";
    const output = parseUint(input, u256);

    try std.testing.expectEqual(0x36cc3b4eb1a6e7079cedee9f7487c8d968bfc9e30db863e533e93f6c7956bba9, output);
}
