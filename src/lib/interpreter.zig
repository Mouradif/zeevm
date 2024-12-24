const std = @import("std");
const config = @import("config");

const OpCode = @import("../types/opcode.zig").OpCode;
const Hash = @import("../utils/hash.zig");

const Context = @import("context.zig");
const AddressState = @import("address_state.zig");

fn signExtend(b: u256, x: u256) u256 {
    const intTypes = .{
        i8,   i16,  i24,  i32,  i40,  i48,  i56,  i64,  i72,  i80,  i88,  i96,  i104, i112, i120,
        i128, i136, i144, i152, i160, i168, i176, i184, i192, i200, i208, i216, i224, i232, i240,
        i248,
    };

    inline for (intTypes, 0..) |T, i| {
        if (@as(u256, i) == b) {
            const signedX: i256 = @bitCast(x);
            const y: T = @as(T, @truncate(signedX));
            const w: i256 = y;
            return @bitCast(w);
        }
    }
    return x;
}

fn getByte(i: u256, x: u256) u256 {
    if (i > 31) return 0;
    const shift: u8 = @truncate((31 - i) * 8);
    const shifted: u256 = x >> shift;
    const b: u8 = @truncate(shifted);
    return b;
}

fn leftShifted(shift: u256, x: u256) u256 {
    if (shift > 255) return 0;
    const sh: u8 = @truncate(shift);
    return x << sh;
}

fn rightShifted(shift: u256, x: u256) u256 {
    if (shift > 255) return 0;
    const sh: u8 = @truncate(shift);
    return x >> sh;
}

fn expBySquaring(x: u256, n: u256) u256 {
    if (n == 0) {
        return 1;
    }
    if (n == 1) {
        return x;
    }
    var next_x: u256 = x *% x;
    var next_n = n;
    if ((n & 1) == 1) {
        next_x *%= x;
        next_n -= 1;
    }

    return expBySquaring(next_x, n >> 1);
}

const Operation = fn (context: *Context) anyerror!void;

fn op_unknown(context: *Context) !void {
    context.status = .Panic;
}

fn op_stop(context: *Context) !void {
    context.status = .Stop;
}

fn op_add(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    if (comptime config.debug) {
        std.debug.print("{d} + {d} = {d}\n", .{
            a,
            b.*,
            a +% b.*,
        });
    }
    b.* = a +% b.*;
}

fn op_mul(context: *Context) !void {
    try context.spendGas(5);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    if (comptime config.debug) {
        std.debug.print("{d} * {d} = {d}\n", .{
            a,
            b.*,
            a *% b.*,
        });
    }
    b.* = a *% b.*;
}

fn op_sub(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    if (comptime config.debug) {
        std.debug.print("{d} - {d} = {d}\n", .{
            a,
            b.*,
            a -% b.*,
        });
    }
    b.* = a -% b.*;
}

fn op_div(context: *Context) !void {
    try context.spendGas(5);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    const result = if (b.* == 0) 0 else @divTrunc(a, b.*);
    if (comptime config.debug) {
        std.debug.print("{d} / {d} = {d}\n", .{
            a,
            b.*,
            result,
        });
    }
    b.* = result;
}

fn op_sdiv(context: *Context) !void {
    try context.spendGas(5);
    try context.stack.ensureHasAtLeast(2);
    const a: i256 = @bitCast(context.stack.pop_unsafe());
    const b = context.stack.peek().?;
    const result = if (b.* == 0) 0 else @divTrunc(a, @as(i256, @bitCast(b.*)));
    if (comptime config.debug) {
        std.debug.print("{d} / {d} = {d}\n", .{
            @as(u256, @bitCast(a)),
            b.*,
            @as(u256, @bitCast(result)),
        });
    }
    b.* = @bitCast(result);
}

fn op_mod(context: *Context) !void {
    try context.spendGas(5);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    const result = if (b.* == 0) 0 else @mod(a, b.*);
    if (comptime config.debug) {
        std.debug.print("{d} % {d} = {d}\n", .{
            a,
            b.*,
            result,
        });
    }
    b.* = result;
}

fn op_smod(context: *Context) !void {
    try context.spendGas(5);
    try context.stack.ensureHasAtLeast(2);
    const a: i256 = @bitCast(context.stack.pop_unsafe());
    const b = context.stack.peek().?;
    const result = if (b.* == 0) 0 else @rem(a, @as(i256, @bitCast(b.*)));
    if (comptime config.debug) {
        std.debug.print("{d} % {d} = {d}\n", .{
            @as(u256, @bitCast(a)),
            b.*,
            @as(u256, @bitCast(result)),
        });
    }
    b.* = @bitCast(result);
}

fn op_addmod(context: *Context) !void {
    try context.spendGas(8);
    try context.stack.ensureHasAtLeast(3);
    const a = context.stack.pop_unsafe();
    const b = context.stack.pop_unsafe();
    const N = context.stack.peek().?;
    if (N.* == 0) {
        return;
    }
    const addition: u512 = @as(u512, @intCast(a)) + @as(u512, @intCast(b));

    const result: u256 = @truncate(@mod(addition, N.*));
    N.* = result;
}

fn op_mulmod(context: *Context) !void {
    try context.spendGas(8);
    try context.stack.ensureHasAtLeast(3);
    const a = context.stack.pop_unsafe();
    const b = context.stack.pop_unsafe();
    const N = context.stack.peek().?;
    if (N.* == 0) {
        return;
    }
    const multiplication: u512 = @as(u512, @intCast(a)) * @as(u512, @intCast(b));
    const result: u256 = @truncate(@mod(multiplication, N.*));
    N.* = result;
}

fn op_exp(context: *Context) !void {
    try context.spendGas(10);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const exponent = context.stack.peek().?;
    exponent.* = expBySquaring(a, exponent.*);
}

fn op_signextend(context: *Context) !void {
    try context.spendGas(5);
    try context.stack.ensureHasAtLeast(2);
    const b = context.stack.pop_unsafe();
    const x = context.stack.peek().?;
    x.* = signExtend(b, x.*);
}

fn op_lt(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    b.* = @intFromBool(a < b.*);
}

fn op_gt(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    b.* = @intFromBool(a > b.*);
}

fn op_slt(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a: i256 = @bitCast(context.stack.pop_unsafe());
    const b = context.stack.peek().?;
    if (comptime config.debug) {
        std.debug.print("SLT {d} < {d}\n", .{
            @as(u256, @bitCast(a)),
            b.*,
        });
    }
    b.* = @intFromBool(a < @as(i256, @bitCast(b.*)));
}

fn op_sgt(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a: i256 = @bitCast(context.stack.pop_unsafe());
    const b = context.stack.peek().?;
    b.* = @intFromBool(a > @as(i256, @bitCast(b.*)));
}

fn op_eq(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    b.* = @intFromBool(a == b.*);
}

fn op_iszero(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(1);
    const a = context.stack.peek().?;
    a.* = @intFromBool(a.* == 0);
}

fn op_and(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    b.* = a & b.*;
}

fn op_or(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    b.* = a | b.*;
}

fn op_xor(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const a = context.stack.pop_unsafe();
    const b = context.stack.peek().?;
    b.* = a ^ b.*;
}

fn op_not(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(1);
    const a = context.stack.peek().?;
    a.* = ~a.*;
}

fn op_byte(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const i = context.stack.pop_unsafe();
    const x = context.stack.peek().?;
    x.* = getByte(i, x.*);
}

fn op_shl(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const shift = context.stack.pop_unsafe();
    const value = context.stack.peek().?;
    value.* = leftShifted(shift, value.*);
}

fn op_shr(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const shift = context.stack.pop_unsafe();
    const value = context.stack.peek().?;
    value.* = rightShifted(shift, value.*);
}

fn op_sar(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(2);
    const shift = context.stack.pop_unsafe();
    const value = context.stack.peek().?;
    var result = rightShifted(shift, value.*);
    if (((1 << 255) & value.*) > 0) {
        const i256_min: i256 = -1;
        const u256_max: u256 = @bitCast(i256_min);
        const mask = leftShifted(256 - shift, u256_max);
        result |= mask;
    }
    value.* = result;
}

fn op_keccak256(context: *Context) !void {
    try context.spendGas(30);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(2);
    const offset = context.stack.pop_unsafe();
    const length = context.stack.peek().?;
    const data = try context.memory.read(offset, length.*);
    const dynamic_cost = 6 * @divTrunc(length.* + 31, 32);
    try context.spendGas(@truncate(dynamic_cost));
    length.* = Hash.keccak256(data);
}

fn op_address(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.address)));
}

fn op_balance(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(1);
    const address = context.stack.peek().?;
    const addr: u160 = @truncate(address.*);
    const address_state = try context.loadAddress(addr);
    address.* = address_state.balance;
}

fn op_origin(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.origin)));
}

fn op_caller(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.caller)));
}

fn op_callvalue(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(context.call_value);
}

fn op_calldataload(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.ensureHasAtLeast(1);
    const i = context.stack.peek().?;
    var calldata_bytes: [32]u8 = undefined;
    for (0..32) |index| {
        const src = @as(usize, @truncate(i.*)) + index;
        const dst = 31 - index;
        const byte = if (i.* + index >= context.call_data.len) 0 else context.call_data[src];
        calldata_bytes[dst] = byte;
    }
    const word: u256 = @bitCast(calldata_bytes);
    i.* = word;
}

fn op_calldatasize(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.call_data.len)));
}

fn op_calldatacopy(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(3);
    const dest_offset = context.stack.pop_unsafe();
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    const dynamic_cost = 3 * @divTrunc(size + 31, 32);
    try context.spendGas(@as(u64, @truncate(dynamic_cost)));
    while (context.memory.buffer.items.len < dest_offset + size) {
        try context.memory.expand();
    }
    const dest_start: usize = @truncate(dest_offset);
    const end: usize = @truncate(dest_offset + size);
    @memset(context.memory.buffer.items[dest_start..end], 0);
    if (offset < context.call_data.len) {
        const start: usize = @truncate(offset);
        const copiable_size: usize = @truncate(context.call_data.len - offset);
        @memcpy(context.memory.buffer.items[dest_start .. dest_start + copiable_size], context.call_data[start .. start + copiable_size]);
    }
}

fn op_codesize(context: *Context) !void {
    try context.spendGas(2);
    const address_state = try context.loadAddress(context.address);
    try context.stack.push(@as(u256, @intCast(address_state.code.?.len)));
}

fn op_codecopy(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(3);
    const dest_offset = context.stack.pop_unsafe();
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    const dynamic_cost = 3 * @divTrunc(size + 31, 32);
    try context.spendGas(@as(u64, @truncate(dynamic_cost)));
    const address_state = try context.loadAddress(context.address);
    while (context.memory.buffer.items.len < dest_offset + size) {
        try context.memory.expand();
    }
    const dest_start: usize = @truncate(dest_offset);
    const u_size: usize = @truncate(size);
    @memset(context.memory.buffer.items[dest_start .. dest_start + u_size], 0);
    if (offset < address_state.code.?.len) {
        const start: usize = @truncate(offset);
        const copiable_size: usize = @truncate(address_state.code.?.len - offset);
        @memcpy(context.memory.buffer.items[dest_start .. dest_start + copiable_size], address_state.code.?[start .. start + copiable_size]);
    }
}

fn op_gasprice(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(context.block.base_fee);
}

fn op_extcodesize(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(1);
    const address = context.stack.peek().?;
    const addr: u160 = @truncate(address.*);
    const address_state = try context.loadAddress(addr);
    address.* = @as(u256, @intCast(address_state.code.?.len));
}

fn op_extcodecopy(context: *Context) !void {
    try context.spendGas(100);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(4);
    const address = context.stack.pop_unsafe();
    const dest_offset = context.stack.pop_unsafe();
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    const dynamic_cost = 3 * @divTrunc(size + 31, 32);
    const addr: u160 = @truncate(address);
    try context.spendGas(@as(u64, @truncate(dynamic_cost)));
    const address_state = try context.loadAddress(addr);
    while (context.memory.buffer.items.len < dest_offset + size) {
        try context.memory.expand();
    }
    const dest_start: usize = @truncate(dest_offset);
    const u_size: usize = @truncate(size);
    @memset(context.memory.buffer.items[dest_start .. dest_start + u_size], 0);
    if (offset < address_state.code.?.len) {
        const start: usize = @truncate(offset);
        const copiable_size: usize = @truncate(address_state.code.?.len - offset);
        @memcpy(context.memory.buffer.items[dest_start .. dest_start + copiable_size], address_state.code.?[start .. start + copiable_size]);
    }
}

fn op_returndatasize(context: *Context) !void {
    try context.spendGas(2);
    const has_return_data: bool = context.child != null and (context.child.?.status == .Return or context.child.?.status == .Revert) and context.child.?.return_data != null;
    const return_data_size: u256 = if (has_return_data) context.child.?.return_data.?.len else 0;
    try context.stack.push(return_data_size);
}

fn op_returndatacopy(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(3);
    const dest_offset = context.stack.pop_unsafe();
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    const dynamic_cost = 3 * @divTrunc(size + 31, 32);
    try context.spendGas(@as(u64, @truncate(dynamic_cost)));
    while (context.memory.buffer.items.len < dest_offset + size) {
        try context.memory.expand();
    }
    const dest_start: usize = @truncate(dest_offset);
    const u_size: usize = @truncate(size);
    @memset(context.memory.buffer.items[dest_start .. dest_start + u_size], 0);
    const has_return_data: bool = context.child != null and (context.child.?.status == .Return or context.child.?.status == .Revert) and context.child.?.return_data != null;
    if (has_return_data and offset < context.child.?.return_data.?.len) {
        const copiable_size: usize = @truncate(context.child.?.return_data.?.len - offset);
        const start: usize = @truncate(offset);
        @memcpy(
            context.memory.buffer.items[dest_start .. dest_start + copiable_size],
            context.child.?.return_data.?[start .. start + copiable_size],
        );
    }
}

fn op_extcodehash(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(1);
    const address = context.stack.peek().?;
    const addr: u160 = @truncate(address.*);
    _ = try context.loadAddress(addr);
    address.* = context.codeHash(addr);
}

fn op_blockhash(context: *Context) !void {
    try context.spendGas(20);
    try context.stack.ensureHasAtLeast(1);
    const block_number = context.stack.peek().?;
    var block_hash: u256 = 0;
    if (block_number.* < context.block.number and context.block.number - block_number.* <= 256) {
        block_hash = context.blockHash(block_number.*);
    }
    block_number.* = block_hash;
}

fn op_coinbase(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.block.coinbase)));
}

fn op_timestamp(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.block.timestamp)));
}

fn op_number(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.block.number)));
}

fn op_prevrandao(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.block.prevrandao)));
}

fn op_gaslimit(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.chain.gas_limit)));
}

fn op_chainid(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.chain.id)));
}

fn op_selfbalance(context: *Context) !void {
    try context.spendGas(5);
    const address_state = try context.loadAddress(context.address);
    try context.stack.push(address_state.balance);
}

fn op_basefee(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(context.block.base_fee);
}

fn op_blobhash(context: *Context) !void {
    try context.spendGas(3);
    try context.stack.push(0);
}

fn op_blobbasefee(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(0);
}

fn op_pop(context: *Context) !void {
    try context.spendGas(2);
    _ = try context.stack.pop();
}

fn op_mload(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(1);
    const offset = context.stack.peek().?;
    const memory_word = try context.memory.load(offset.*);
    offset.* = memory_word;
}

fn op_mstore(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(2);
    const offset = context.stack.pop_unsafe();
    const value = context.stack.pop_unsafe();
    try context.memory.store(offset, value);
}

fn op_mstore8(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(2);
    const offset = context.stack.pop_unsafe();
    const value = context.stack.pop_unsafe();
    const b: u8 = @truncate(value);
    try context.memory.storeByte(offset, b);
}

fn op_sload(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(1);
    const slot = context.stack.peek().?;
    slot.* = try context.loadStorageSlot(slot.*);
}

fn op_sstore(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(2);
    const slot = context.stack.pop_unsafe();
    const value = context.stack.pop_unsafe();
    try context.writeStorageSlot(slot, value);
}

fn op_jump(context: *Context) !void {
    try context.spendGas(8);
    const counter = try context.stack.pop();
    context.program_counter = @truncate(counter);
    try context.ensureValidJumpDestination();
}

fn op_jumpi(context: *Context) !void {
    try context.spendGas(10);
    try context.stack.ensureHasAtLeast(2);
    const counter = context.stack.pop_unsafe();
    const b = context.stack.pop_unsafe();
    if (b > 0) {
        context.program_counter = @truncate(counter);
        try context.ensureValidJumpDestination();
    }
}

fn op_pc(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.program_counter)));
}

fn op_msize(context: *Context) !void {
    try context.spendGas(2);
    const memory_size: u256 = @intCast(context.memory.buffer.items.len);
    try context.stack.push(memory_size);
}

fn op_gas(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.gas)));
}

fn op_jumpdest(context: *Context) !void {
    try context.spendGas(1);
}

fn op_tload(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(1);
    const key = context.stack.peek().?;
    const address_state = try context.loadAddress(context.address);
    const word = address_state.tLoad(key.*);
    key.* = word;
}

fn op_tstore(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(2);
    const key = context.stack.pop_unsafe();
    const value = context.stack.pop_unsafe();
    const address_state = try context.loadAddress(context.address);
    try address_state.tStore(key, value);
}

// TODO: implement
fn op_mcopy(context: *Context) !void {
    _ = context;
}

fn op_push0(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(0);
}

fn op_push1(context: *Context) !void {
    try context.push(1);
}

fn op_push2(context: *Context) !void {
    try context.push(2);
}

fn op_push3(context: *Context) !void {
    try context.push(3);
}

fn op_push4(context: *Context) !void {
    try context.push(4);
}

fn op_push5(context: *Context) !void {
    try context.push(5);
}

fn op_push6(context: *Context) !void {
    try context.push(6);
}

fn op_push7(context: *Context) !void {
    try context.push(7);
}

fn op_push8(context: *Context) !void {
    try context.push(8);
}

fn op_push9(context: *Context) !void {
    try context.push(9);
}

fn op_push10(context: *Context) !void {
    try context.push(10);
}

fn op_push11(context: *Context) !void {
    try context.push(11);
}

fn op_push12(context: *Context) !void {
    try context.push(12);
}

fn op_push13(context: *Context) !void {
    try context.push(13);
}

fn op_push14(context: *Context) !void {
    try context.push(14);
}

fn op_push15(context: *Context) !void {
    try context.push(15);
}

fn op_push16(context: *Context) !void {
    try context.push(16);
}

fn op_push17(context: *Context) !void {
    try context.push(17);
}

fn op_push18(context: *Context) !void {
    try context.push(18);
}

fn op_push19(context: *Context) !void {
    try context.push(19);
}

fn op_push20(context: *Context) !void {
    try context.push(20);
}

fn op_push21(context: *Context) !void {
    try context.push(21);
}

fn op_push22(context: *Context) !void {
    try context.push(22);
}

fn op_push23(context: *Context) !void {
    try context.push(23);
}

fn op_push24(context: *Context) !void {
    try context.push(24);
}

fn op_push25(context: *Context) !void {
    try context.push(25);
}

fn op_push26(context: *Context) !void {
    try context.push(26);
}

fn op_push27(context: *Context) !void {
    try context.push(27);
}

fn op_push28(context: *Context) !void {
    try context.push(28);
}

fn op_push29(context: *Context) !void {
    try context.push(29);
}

fn op_push30(context: *Context) !void {
    try context.push(30);
}

fn op_push31(context: *Context) !void {
    try context.push(31);
}

fn op_push32(context: *Context) !void {
    try context.push(32);
}

fn op_dup1(context: *Context) !void {
    try context.dup(1);
}

fn op_dup2(context: *Context) !void {
    try context.dup(2);
}

fn op_dup3(context: *Context) !void {
    try context.dup(3);
}

fn op_dup4(context: *Context) !void {
    try context.dup(4);
}

fn op_dup5(context: *Context) !void {
    try context.dup(5);
}

fn op_dup6(context: *Context) !void {
    try context.dup(6);
}

fn op_dup7(context: *Context) !void {
    try context.dup(7);
}

fn op_dup8(context: *Context) !void {
    try context.dup(8);
}

fn op_dup9(context: *Context) !void {
    try context.dup(9);
}

fn op_dup10(context: *Context) !void {
    try context.dup(10);
}

fn op_dup11(context: *Context) !void {
    try context.dup(11);
}

fn op_dup12(context: *Context) !void {
    try context.dup(12);
}

fn op_dup13(context: *Context) !void {
    try context.dup(13);
}

fn op_dup14(context: *Context) !void {
    try context.dup(14);
}

fn op_dup15(context: *Context) !void {
    try context.dup(15);
}

fn op_dup16(context: *Context) !void {
    try context.dup(16);
}

fn op_swap1(context: *Context) !void {
    try context.swap(1);
}

fn op_swap2(context: *Context) !void {
    try context.swap(2);
}

fn op_swap3(context: *Context) !void {
    try context.swap(3);
}

fn op_swap4(context: *Context) !void {
    try context.swap(4);
}

fn op_swap5(context: *Context) !void {
    try context.swap(5);
}

fn op_swap6(context: *Context) !void {
    try context.swap(6);
}

fn op_swap7(context: *Context) !void {
    try context.swap(7);
}

fn op_swap8(context: *Context) !void {
    try context.swap(8);
}

fn op_swap9(context: *Context) !void {
    try context.swap(9);
}

fn op_swap10(context: *Context) !void {
    try context.swap(10);
}

fn op_swap11(context: *Context) !void {
    try context.swap(11);
}

fn op_swap12(context: *Context) !void {
    try context.swap(12);
}

fn op_swap13(context: *Context) !void {
    try context.swap(13);
}

fn op_swap14(context: *Context) !void {
    try context.swap(14);
}

fn op_swap15(context: *Context) !void {
    try context.swap(15);
}

fn op_swap16(context: *Context) !void {
    try context.swap(16);
}

fn op_log0(context: *Context) !void {
    try context.spendGas(375);
    const initial_memory_cost = context.memory.cost();
    const topics = try context.allocator.alloc(u256, 0);
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
        context.allocator.free(topics);
    }
    try context.stack.ensureHasAtLeast(2);
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    const data = try context.memory.read(offset, size);
    const dynamic_cost = 8 * @divTrunc(size + 31, 32);
    try context.spendGas(@truncate(dynamic_cost));
    try context.emitLog(topics, data);
}

fn op_log1(context: *Context) !void {
    try context.spendGas(750);
    const initial_memory_cost = context.memory.cost();
    const topics = try context.allocator.alloc(u256, 1);
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
        context.allocator.free(topics);
    }
    try context.stack.ensureHasAtLeast(3);
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    topics[0] = context.stack.pop_unsafe();
    const data = try context.memory.read(offset, size);
    const dynamic_cost = 8 * @divTrunc(size + 31, 32);
    try context.spendGas(@truncate(dynamic_cost));
    try context.emitLog(topics, data);
}

fn op_log2(context: *Context) !void {
    try context.spendGas(1125);
    const initial_memory_cost = context.memory.cost();
    const topics = try context.allocator.alloc(u256, 2);
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
        context.allocator.free(topics);
    }
    try context.stack.ensureHasAtLeast(4);
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    topics[0] = context.stack.pop_unsafe();
    topics[1] = context.stack.pop_unsafe();
    const data = try context.memory.read(offset, size);
    const dynamic_cost = 8 * @divTrunc(size + 31, 32);
    try context.spendGas(@truncate(dynamic_cost));
    try context.emitLog(topics, data);
}

fn op_log3(context: *Context) !void {
    try context.spendGas(1500);
    const initial_memory_cost = context.memory.cost();
    const topics = try context.allocator.alloc(u256, 3);
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
        context.allocator.free(topics);
    }
    try context.stack.ensureHasAtLeast(5);
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    topics[0] = context.stack.pop_unsafe();
    topics[1] = context.stack.pop_unsafe();
    topics[2] = context.stack.pop_unsafe();
    const data = try context.memory.read(offset, size);
    const dynamic_cost = 8 * @divTrunc(size + 31, 32);
    try context.spendGas(@truncate(dynamic_cost));
    try context.emitLog(topics, data);
}

fn op_log4(context: *Context) !void {
    try context.spendGas(1875);
    const initial_memory_cost = context.memory.cost();
    const topics = try context.allocator.alloc(u256, 4);
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
        context.allocator.free(topics);
    }
    try context.stack.ensureHasAtLeast(6);
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    topics[0] = context.stack.pop_unsafe();
    topics[1] = context.stack.pop_unsafe();
    topics[2] = context.stack.pop_unsafe();
    topics[3] = context.stack.pop_unsafe();
    const data = try context.memory.read(offset, size);
    const dynamic_cost = 8 * @divTrunc(size + 31, 32);
    try context.spendGas(@truncate(dynamic_cost));
    try context.emitLog(topics, data);
}

fn op_create(context: *Context) !void {
    try context.spendGas(32000);
    try context.stack.ensureHasAtLeast(3);
    const value = context.stack.pop_unsafe();
    const offset = context.stack.pop_unsafe();
    const size = context.stack.peek().?;
    _ = value;
    _ = offset;
    size.* = 0;
}

fn op_call(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(7);
    const gas = context.stack.pop_unsafe();
    const address = context.stack.pop_unsafe();
    const value = context.stack.pop_unsafe();
    const args_offset = context.stack.pop_unsafe();
    const args_size = context.stack.pop_unsafe();
    const ret_offset = context.stack.pop_unsafe();
    const ret_length = context.stack.pop_unsafe();
    const data = try context.memory.copy_zerofill(args_offset, args_size);
    try context.memory.expandToOffset(ret_offset, ret_length);
    context.call_result_offset = ret_offset;
    context.call_result_length = ret_length;
    try context.spawn(
        @truncate(address),
        value,
        data,
        @truncate(gas),
        false
    );
}

fn op_callcode(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(7);
    const gas = context.stack.pop_unsafe();
    const address = context.stack.pop_unsafe();
    const value = context.stack.pop_unsafe();
    const args_offset = context.stack.pop_unsafe();
    const args_size = context.stack.pop_unsafe();
    const ret_offset = context.stack.pop_unsafe();
    const ret_size = context.stack.peek().?;
    _ = gas;
    _ = address;
    _ = value;
    _ = args_offset;
    _ = args_size;
    _ = ret_offset;
    ret_size.* = 1;
}

fn op_return(context: *Context) !void {
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(2);
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    context.return_data = try context.memory.expand_and_copy(offset, size);
    context.status = .Return;
}

fn op_delegatecall(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(6);
    const gas = context.stack.pop_unsafe();
    const address = context.stack.pop_unsafe();
    const args_offset = context.stack.pop_unsafe();
    const args_size = context.stack.pop_unsafe();
    const ret_offset = context.stack.pop_unsafe();
    const ret_size = context.stack.peek().?;
    _ = gas;
    _ = address;
    _ = args_offset;
    _ = args_size;
    _ = ret_offset;
    ret_size.* = 1;
}

fn op_create2(context: *Context) !void {
    try context.spendGas(32000);
    try context.stack.ensureHasAtLeast(4);
    const value = context.stack.pop_unsafe();
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    const salt = context.stack.peek().?;
    _ = value;
    _ = offset;
    _ = size;
    salt.* = 0;
}

fn op_staticcall(context: *Context) !void {
    try context.spendGas(100);
    try context.stack.ensureHasAtLeast(6);
    const gas = context.stack.pop_unsafe();
    const address = context.stack.pop_unsafe();
    const args_offset = context.stack.pop_unsafe();
    const args_size = context.stack.pop_unsafe();
    const ret_offset = context.stack.pop_unsafe();
    const ret_size = context.stack.peek().?;
    _ = gas;
    _ = address;
    _ = args_offset;
    _ = args_size;
    _ = ret_offset;
    ret_size.* = 1;
}

fn op_revert(context: *Context) !void {
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    try context.stack.ensureHasAtLeast(2);
    const offset = context.stack.pop_unsafe();
    const size = context.stack.pop_unsafe();
    context.return_data = try context.memory.expand_and_copy(offset, size);
    context.status = .Revert;
}

fn op_invalid(context: *Context) !void {
    try context.spendGas(context.gas);
    context.status = .Panic;
}

fn op_selfdestruct(context: *Context) !void {
    try context.spendGas(5000);
    const a = try context.stack.pop();
    _ = a;
    context.status = .Stop;
}

pub const runTable: [256]*const Operation = .{
    op_stop,
    op_add,
    op_mul,
    op_sub,
    op_div,
    op_sdiv,
    op_mod,
    op_smod,
    op_addmod,
    op_mulmod,
    op_exp,
    op_signextend,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_lt,
    op_gt,
    op_slt,
    op_sgt,
    op_eq,
    op_iszero,
    op_and,
    op_or,
    op_xor,
    op_not,
    op_byte,
    op_shl,
    op_shr,
    op_sar,
    op_unknown,
    op_unknown,
    op_keccak256,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_address,
    op_balance,
    op_origin,
    op_caller,
    op_callvalue,
    op_calldataload,
    op_calldatasize,
    op_calldatacopy,
    op_codesize,
    op_codecopy,
    op_gasprice,
    op_extcodesize,
    op_extcodecopy,
    op_returndatasize,
    op_returndatacopy,
    op_extcodehash,
    op_blockhash,
    op_coinbase,
    op_timestamp,
    op_number,
    op_prevrandao,
    op_gaslimit,
    op_chainid,
    op_selfbalance,
    op_basefee,
    op_blobhash,
    op_blobbasefee,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_pop,
    op_mload,
    op_mstore,
    op_mstore8,
    op_sload,
    op_sstore,
    op_jump,
    op_jumpi,
    op_pc,
    op_msize,
    op_gas,
    op_jumpdest,
    op_tload,
    op_tstore,
    op_mcopy,
    op_push0,
    op_push1,
    op_push2,
    op_push3,
    op_push4,
    op_push5,
    op_push6,
    op_push7,
    op_push8,
    op_push9,
    op_push10,
    op_push11,
    op_push12,
    op_push13,
    op_push14,
    op_push15,
    op_push16,
    op_push17,
    op_push18,
    op_push19,
    op_push20,
    op_push21,
    op_push22,
    op_push23,
    op_push24,
    op_push25,
    op_push26,
    op_push27,
    op_push28,
    op_push29,
    op_push30,
    op_push31,
    op_push32,
    op_dup1,
    op_dup2,
    op_dup3,
    op_dup4,
    op_dup5,
    op_dup6,
    op_dup7,
    op_dup8,
    op_dup9,
    op_dup10,
    op_dup11,
    op_dup12,
    op_dup13,
    op_dup14,
    op_dup15,
    op_dup16,
    op_swap1,
    op_swap2,
    op_swap3,
    op_swap4,
    op_swap5,
    op_swap6,
    op_swap7,
    op_swap8,
    op_swap9,
    op_swap10,
    op_swap11,
    op_swap12,
    op_swap13,
    op_swap14,
    op_swap15,
    op_swap16,
    op_log0,
    op_log1,
    op_log2,
    op_log3,
    op_log4,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_create,
    op_call,
    op_callcode,
    op_return,
    op_delegatecall,
    op_create2,
    op_unknown,
    op_unknown,
    op_unknown,
    op_unknown,
    op_staticcall,
    op_unknown,
    op_unknown,
    op_revert,
    op_invalid,
    op_selfdestruct,
};

const t = std.testing;

fn testTake3Return1(op: Operation, a: u256, b: u256, c: u256, n: u256, gas: u64) !void {
    var context = Context.init(t.allocator, .{});
    try context.stack.push(a);
    try context.stack.push(b);
    try context.stack.push(c);
    const gas_start = context.gas;
    try op(&context);
    try t.expectEqual(n, context.stack.pop_unsafe());
    try t.expectEqual(gas, gas_start - context.gas);
}

fn testTake2Return1(op: Operation, a: u256, b: u256, n: u256, gas: u64) !void {
    var context = Context.init(t.allocator, .{});
    try context.stack.push(a);
    try context.stack.push(b);
    const gas_start = context.gas;
    try op(&context);
    try t.expectEqual(n, context.stack.pop_unsafe());
    try t.expectEqual(gas, gas_start - context.gas);
}

test "Interpreter: add small numbers" {
    try testTake2Return1(op_add, 19, 23, 42, 3);
}

test "Interpreter: add big numbers" {
    try testTake2Return1(
        op_add,
        0x384b0e6b92e5a98ecac63a19704f2f1354361cd3c9fb2e45553f0873436d7c99,
        0x797258a83b079434804b3ced2ef589806a83df89abab30903b89b9612459b6e4,
        0xb1bd6713cded3dc34b1177069f44b893beb9fc5d75a65ed590c8c1d467c7337d,
        3,
    );
}

test "Interpreter: add with overflow" {
    try testTake2Return1(
        op_add,
        0x6aedb884af2f8847fb585fc13b7bddd13803229aea6dbeb80c201e4b11f8bb41,
        0xb04bc6f9430946ca2ca34b416c72204fbbf67e17104efa55f6ac985a7568566b,
        0x1b397f7df238cf1227fbab02a7edfe20f3f9a0b1fabcb90e02ccb6a5876111ac,
        3,
    );
}

test "Interpreter: mul small numbers" {
    try testTake2Return1(
        op_mul,
        19,
        23,
        437,
        5,
    );
}

test "Interpreter: mul big numbers" {
    try testTake2Return1(
        op_mul,
        0x43830e1f057acc81e04b11ff4189ca26,
        0xcad3060011b012e67e5571e1c13155ab,
        0x357d0fbe34e346bbaf90f91720c6f54f7da0114170f39cd2e056a46fde6ea562,
        5,
    );
}

test "Interpreter: mul with overflow" {
    try testTake2Return1(
        op_mul,
        0xc76d60218e4d8bf77f7c34317d605b1c18faba2c93dcb885,
        0x226e544fe816a9df22435008a96515f323ee63ff4078c9f6,
        0x364b2e5031147110695b82e282b1f4494475bea1f21163f1a5d5a0012151bcce,
        5,
    );
}

test "Interpreter: sub small numbers" {
    try testTake2Return1(
        op_sub,
        19,
        23,
        4,
        3,
    );
}

test "Interpreter: sub big numbers" {
    try testTake2Return1(
        op_sub,
        0x384b0e6b92e5a98ecac63a19704f2f1354361cd3c9fb2e45553f0873436d7c99,
        0x797258a83b079434804b3ced2ef589806a83df89abab30903b89b9612459b6e4,
        0x41274a3ca821eaa5b58502d3bea65a6d164dc2b5e1b0024ae64ab0ede0ec3a4b,
        3,
    );
}

test "Interpreter: sub with underflow" {
    try testTake2Return1(
        op_sub,
        0xb04bc6f9430946ca2ca34b416c72204fbbf67e17104efa55f6ac985a7568566b,
        0x6aedb884af2f8847fb585fc13b7bddd13803229aea6dbeb80c201e4b11f8bb41,
        0xbaa1f18b6c26417dceb5147fcf09bd817c0ca483da1ec462157385f09c9064d6,
        3,
    );
}

test "Interpreter: div by zero" {
    try testTake2Return1(
        op_div,
        2,
        0,
        0,
        5,
    );
}

test "Interpreter: div small numbers" {
    try testTake2Return1(
        op_div,
        3,
        27,
        9,
        5,
    );
}

test "Interpreter: div big numbers" {
    try testTake2Return1(
        op_div,
        0x5e3bd29da9933a9d4763,
        0x452f607a94dc1d59bf65a6a2c38abf6f267d9112b1f182d3f8c0158ac39f83f5,
        0xbbf39fdcf785048ed3fc042be42adbb808b42d5ca3ca,
        5,
    );
}

test "Interpreter: div with bigger denominator" {
    try testTake2Return1(
        op_div,
        0x452f607a94dc1d59bf65a6a2c38abf6f267d9112b1f182d3f8c0158ac39f83f5,
        0x5e3bd29da9933a9d4763,
        0,
        5,
    );
}

test "Interpreter: sdiv small numbers" {
    try testTake2Return1(
        op_div,
        3,
        27,
        9,
        5,
    );
}

test "Interpreter: sdiv negative numerator" {
    try testTake2Return1(
        op_sdiv,
        3,
        @bitCast(@as(i256, -27)),
        @bitCast(@as(i256, -9)),
        5,
    );
}

test "Interpreter: sdiv negative denominator" {
    try testTake2Return1(
        op_sdiv,
        @bitCast(@as(i256, -3)),
        27,
        @bitCast(@as(i256, -9)),
        5,
    );
}

test "Interpreter: sdiv negative both terms" {
    try testTake2Return1(
        op_sdiv,
        @bitCast(@as(i256, -3)),
        @bitCast(@as(i256, -27)),
        9,
        5,
    );
}

test "Interpreter: sdiv positive by zero" {
    try testTake2Return1(
        op_sdiv,
        0,
        27,
        0,
        5,
    );
}

test "Interpreter: sdiv negative by zero" {
    try testTake2Return1(
        op_sdiv,
        0,
        @bitCast(@as(i256, -27)),
        0,
        5,
    );
}

test "Interpreter: sdiv negative by bigger number" {
    try testTake2Return1(
        op_sdiv,
        28,
        @bitCast(@as(i256, -27)),
        0,
        5,
    );
}

test "Interpreter: sdiv negative by positive equivalent" {
    try testTake2Return1(
        op_sdiv,
        27,
        @bitCast(@as(i256, -27)),
        @bitCast(@as(i256, -1)),
        5,
    );
}

test "Interpreter: mod small numbers" {
    try testTake2Return1(
        op_mod,
        4,
        9,
        1,
        5,
    );
}

test "Interpreter: mod bigger denominator" {
    try testTake2Return1(
        op_mod,
        9,
        4,
        4,
        5,
    );
}

test "Interpreter: smod small numbers" {
    try testTake2Return1(
        op_smod,
        4,
        27,
        3,
        5,
    );
}

test "Interpreter: smod negative numerator" {
    try testTake2Return1(
        op_smod,
        4,
        @bitCast(@as(i256, -27)),
        @bitCast(@as(i256, -3)),
        5,
    );
}

test "Interpreter: smod negative denominator" {
    try testTake2Return1(
        op_smod,
        @bitCast(@as(i256, -3)),
        28,
        1,
        5,
    );
}

test "Interpreter: smod negative both terms" {
    try testTake2Return1(
        op_smod,
        @bitCast(@as(i256, -3)),
        @bitCast(@as(i256, -29)),
        @bitCast(@as(i256, -2)),
        5,
    );
}

test "Interpreter: smod positive by zero" {
    try testTake2Return1(
        op_smod,
        0,
        150,
        0,
        5,
    );
}

test "Interpreter: smod negative by zero" {
    try testTake2Return1(
        op_smod,
        0,
        @bitCast(@as(i256, -27)),
        0,
        5,
    );
}

test "Interpreter: smod negative by bigger number" {
    try testTake2Return1(
        op_smod,
        28,
        @bitCast(@as(i256, -27)),
        @bitCast(@as(i256, -27)),
        5,
    );
}

test "Interpreter: smod negative by positive equivalent" {
    try testTake2Return1(
        op_smod,
        27,
        @bitCast(@as(i256, -27)),
        0,
        5,
    );
}

test "Interpreter: addMod small numbers" {
    try testTake3Return1(
        op_addmod,
        5,
        9,
        4,
        3,
        8,
    );
}

test "Interpreter: addMod with modulo by zero" {
    try testTake3Return1(
        op_addmod,
        0,
        5,
        4,
        0,
        8,
    );
}

test "Interpreter: addMod with overflowing addition" {
    try testTake3Return1(
        op_addmod,
        5,
        @bitCast(@as(i256, -1)),
        43,
        3,
        8,
    );
}

test "Interpreter: mulMod small numbers" {
    try testTake3Return1(
        op_mulmod,
        5,
        9,
        4,
        1,
        8,
    );
}

test "Interpreter: mulMod with modulo by zero" {
    try testTake3Return1(
        op_mulmod,
        0,
        5,
        4,
        0,
        8,
    );
}

test "Interpreter: mulMod with overflowing multiplication" {
    try testTake3Return1(
        op_mulmod,
        532,
        @bitCast(@as(i256, -1)),
        @bitCast(@as(i256, -3)),
        195,
        8,
    );
}

test "Interpreter: exp small numbers" {
    try testTake2Return1(
        op_exp,
        3,
        42,
        74088,
        10,
    );
}

// test "Interpreter: exp overflowing" {
//     try testTake2Return1(
//         op_exp,
//         56,
//         0x232e7c4ae3aecef0b2c4120ee596d90401f3589dc7ec55977e3b1f9d1f76fef3,
//         0xeaf1aaaff6acc40ea5a9e957cf500ee1991f947bfc107b530f3cd7e5e6fb5ce1,
//         10,
//     );
// }
