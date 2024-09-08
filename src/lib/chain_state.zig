const std = @import("std");
const Address = @import("address.zig").Address;
const AddressState = @import("address_state.zig");
const Hash = @import("utils/hash.zig");

const Self = @This();

allocator: std.mem.Allocator,
address_states: *std.AutoHashMap(Address, *AddressState),

pub fn init(allocator: std.mem.Allocator) Self {
    var address_states = std.AutoHashMap(Address, *AddressState).init(allocator);
    const state: Self = .{
        .allocator = allocator,
        .address_states = &address_states,
    };
    return state;
}

pub fn deinit(self: *Self) void {
    self.address_states.deinit();
}

pub fn getCode(self: *const Self, address: Address) []const u8 {
    if (self.address_states.get(address)) |state| {
        return state.code;
    }
    return "";
}

pub fn codeHash(self: *Self, address: Address) u256 {
    const code = self.getCode(address);
    return Hash.keccak256(code);
}

test "Get code returns empty bytes for unknown address" {
    var state = Self.init(std.testing.allocator);
    defer state.deinit();
    const code = state.getCode(0);

    try std.testing.expectEqual(0, code.len);
}

test "Get code returns code for known contract" {
    var state = Self.init(std.testing.allocator);
    defer state.deinit();

    const opcodes: [10]u8 = .{ 0x60, 0x2a, 0x51, 0x59, 0x5f, 0x52, 0x60, 0x20, 0x90, 0xf3 };
    const code = try std.testing.allocator.alloc(u8, 10);
    defer std.testing.allocator.free(code);
    for (opcodes, 0..) |opcode, i| {
        code[i] = opcode;
    }
    var address_state = AddressState.init(std.testing.allocator, 0, 0, code);
    defer address_state.deinit();
    try state.address_states.put(0, &address_state);

    const retrieved_code = state.getCode(0);
    try std.testing.expectEqual(10, retrieved_code.len);
    try std.testing.expectEqual(code, retrieved_code);
}

test "Codehash returns code hash" {
    const code_hash: u256 = 0x36cc3b4eb1a6e7079cedee9f7487c8d968bfc9e30db863e533e93f6c7956bba9;

    var state = Self.init(std.testing.allocator);
    defer state.deinit();

    const opcodes: [10]u8 = .{ 0x60, 0x2a, 0x51, 0x59, 0x5f, 0x52, 0x60, 0x20, 0x90, 0xf3 };
    const code = try std.testing.allocator.alloc(u8, 10);
    defer std.testing.allocator.free(code);
    for (opcodes, 0..) |opcode, i| {
        code[i] = opcode;
    }
    var address_state = AddressState.init(std.testing.allocator, 0, 0, code);
    defer address_state.deinit();
    try state.address_states.put(0, &address_state);

    const retrieved_code_hash = state.codeHash(0);
    try std.testing.expectEqual(code_hash, retrieved_code_hash);
}

test "Valid codehash for empty code" {
    const code_hash: u256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    var state = Self.init(std.testing.allocator);
    defer state.deinit();

    const retrieved_code_hash = state.codeHash(0);
    try std.testing.expectEqual(code_hash, retrieved_code_hash);
}
