const std = @import("std");
const config = @import("config");

const OpCode = @import("../types/opcode.zig").OpCode;
const Hash = @import("../utils/hash.zig");

const Context = @import("context.zig");
const AddressState = @import("address_state.zig");

fn signExtend(b: u256, x: u256) u256 {
    switch (b) {
        0 => {
            const y: i8 = @bitCast(@as(u8, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        1 => {
            const y: i16 = @bitCast(@as(u16, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        2 => {
            const y: i24 = @bitCast(@as(u24, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        3 => {
            const y: i32 = @bitCast(@as(u32, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        4 => {
            const y: i40 = @bitCast(@as(u40, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        5 => {
            const y: i48 = @bitCast(@as(u48, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        6 => {
            const y: i56 = @bitCast(@as(u56, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        7 => {
            const y: i64 = @bitCast(@as(u64, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        8 => {
            const y: i72 = @bitCast(@as(u72, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        9 => {
            const y: i80 = @bitCast(@as(u80, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        10 => {
            const y: i88 = @bitCast(@as(u88, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        11 => {
            const y: i96 = @bitCast(@as(u96, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        12 => {
            const y: i104 = @bitCast(@as(u104, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        13 => {
            const y: i112 = @bitCast(@as(u112, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        14 => {
            const y: i120 = @bitCast(@as(u120, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        15 => {
            const y: i128 = @bitCast(@as(u128, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        16 => {
            const y: i136 = @bitCast(@as(u136, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        17 => {
            const y: i144 = @bitCast(@as(u144, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        18 => {
            const y: i152 = @bitCast(@as(u152, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        19 => {
            const y: i160 = @bitCast(@as(u160, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        20 => {
            const y: i168 = @bitCast(@as(u168, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        21 => {
            const y: i176 = @bitCast(@as(u176, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        22 => {
            const y: i184 = @bitCast(@as(u184, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        23 => {
            const y: i192 = @bitCast(@as(u192, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        24 => {
            const y: i200 = @bitCast(@as(u200, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        25 => {
            const y: i208 = @bitCast(@as(u208, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        26 => {
            const y: i216 = @bitCast(@as(u216, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        27 => {
            const y: i224 = @bitCast(@as(u224, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        28 => {
            const y: i232 = @bitCast(@as(u232, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        29 => {
            const y: i240 = @bitCast(@as(u240, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        30 => {
            const y: i248 = @bitCast(@as(u248, @truncate(x)));
            const w: i256 = y;
            const z: u256 = @bitCast(w);
            return z;
        },
        else => return x,
    }
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

const Operation = fn (context: *Context) anyerror!void;

fn op_unknown(context: *Context) !void {
    context.status = .Panic;
}

fn op_stop(context: *Context) !void {
    context.status = .Stop;
}

fn op_add(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    if (comptime config.debug) {
        std.debug.print("{d} + {d} = {d}\n", .{ a, b, a +% b });
    }
    try context.stack.push(a +% b);
}

fn op_mul(context: *Context) !void {
    try context.spendGas(5);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    if (comptime config.debug) {
        std.debug.print("{d} * {d} = {d}\n", .{ a, b, a *% b });
    }
    try context.stack.push(a *% b);
}

fn op_sub(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    if (comptime config.debug) {
        std.debug.print("{d} - {d} = {d}\n", .{ a, b, a -% b });
    }
    try context.stack.push(a -% b);
}

fn op_div(context: *Context) !void {
    try context.spendGas(5);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    const result = if (b == 0) 0 else @divTrunc(a, b);
    if (comptime config.debug) {
        std.debug.print("{d} / {d} = {d}\n", .{ a, b, result });
    }
    try context.stack.push(result);
}

fn op_sdiv(context: *Context) !void {
    try context.spendGas(5);
    const a: i256 = @bitCast(try context.stack.pop());
    const b: i256 = @bitCast(try context.stack.pop());
    const result = if (b == 0) 0 else @divTrunc(a, b);
    if (comptime config.debug) {
        std.debug.print("{d} / {d} = {d}\n", .{ @as(u256, @bitCast(a)), @as(u256, @bitCast(b)), @as(u256, @bitCast(result)) });
    }
    try context.stack.push(@as(u256, @bitCast(result)));
}

fn op_mod(context: *Context) !void {
    try context.spendGas(5);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    const result = if (b == 0) 0 else @mod(a, b);
    if (comptime config.debug) {
        std.debug.print("{d} % {d} = {d}\n", .{ a, b, result });
    }
    try context.stack.push(result);
}

fn op_smod(context: *Context) !void {
    try context.spendGas(5);
    const a: i256 = @bitCast(try context.stack.pop());
    const b: i256 = @bitCast(try context.stack.pop());
    const result = if (b == 0) 0 else @rem(a, b);
    if (comptime config.debug) {
        std.debug.print("{d} % {d} = {d}\n", .{ @as(u256, @bitCast(a)), @as(u256, @bitCast(b)), @as(u256, @bitCast(result)) });
    }
    try context.stack.push(@as(u256, @bitCast(result)));
}

fn op_addmod(context: *Context) !void {
    try context.spendGas(8);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    const N = try context.stack.pop();
    const result = if (N == 0) 0 else @mod(a + b, N);
    try context.stack.push(result);
}

fn op_mulmod(context: *Context) !void {
    try context.spendGas(8);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    const N = try context.stack.pop();
    const result = if (N == 0) 0 else @mod(a * b, N);
    try context.stack.push(result);
}

fn op_exp(context: *Context) !void {
    try context.spendGas(10);
    const a = try context.stack.pop();
    const exponent = try context.stack.pop();
    try context.stack.push(std.math.pow(u256, a, exponent));
}

fn op_signextend(context: *Context) !void {
    try context.spendGas(5);
    const b = try context.stack.pop();
    const x = try context.stack.pop();
    try context.stack.push(signExtend(b, x));
}

fn op_lt(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    try context.stack.push(@intFromBool(a < b));
}

fn op_gt(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    try context.stack.push(@intFromBool(a > b));
}

fn op_slt(context: *Context) !void {
    try context.spendGas(3);
    const a: i256 = @bitCast(try context.stack.pop());
    const b: i256 = @bitCast(try context.stack.pop());
    if (comptime config.debug) {
        std.debug.print("SLT {d} < {d}\n", .{ @as(u256, @bitCast(a)), @as(u256, @bitCast(b)) });
    }
    try context.stack.push(@intFromBool(a < b));
}

fn op_sgt(context: *Context) !void {
    try context.spendGas(3);
    const a: i256 = @bitCast(try context.stack.pop());
    const b: i256 = @bitCast(try context.stack.pop());
    try context.stack.push(@intFromBool(a > b));
}

fn op_eq(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    try context.stack.push(@intFromBool(a == b));
}

fn op_iszero(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    try context.stack.push(@intFromBool(a == 0));
}

fn op_and(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    try context.stack.push(a & b);
}

fn op_or(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    try context.stack.push(a | b);
}

fn op_xor(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    const b = try context.stack.pop();
    try context.stack.push(a ^ b);
}

fn op_not(context: *Context) !void {
    try context.spendGas(3);
    const a = try context.stack.pop();
    try context.stack.push(~a);
}

fn op_byte(context: *Context) !void {
    try context.spendGas(3);
    const i = try context.stack.pop();
    const x = try context.stack.pop();
    try context.stack.push(getByte(i, x));
}

fn op_shl(context: *Context) !void {
    try context.spendGas(3);
    const shift = try context.stack.pop();
    const value = try context.stack.pop();
    try context.stack.push(leftShifted(shift, value));
}

fn op_shr(context: *Context) !void {
    try context.spendGas(3);
    const shift = try context.stack.pop();
    const value = try context.stack.pop();
    try context.stack.push(rightShifted(shift, value));
}

fn op_sar(context: *Context) !void {
    try context.spendGas(3);
    const shift = try context.stack.pop();
    const value = try context.stack.pop();
    const isNegative: bool = ((1 << 255) & value) > 0;
    var result = rightShifted(shift, value);
    if (isNegative) {
        const i256_min: i256 = -1;
        const u256_max: u256 = @bitCast(i256_min);
        const mask = leftShifted(256 - shift, u256_max);
        result |= mask;
    }
    try context.stack.push(result);
}

fn op_keccak256(context: *Context) !void {
    try context.spendGas(30);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    const offset = try context.stack.pop();
    const length = try context.stack.pop();
    const data = try context.memory.read(offset, length);
    const dynamic_cost = 6 * @divFloor(length + 31, 32);
    try context.spendGas(@truncate(dynamic_cost));
    defer context.memory.allocator.free(data);
    try context.stack.push(Hash.keccak256(data));
}

fn op_address(context: *Context) !void {
    try context.spendGas(2);
    try context.stack.push(@as(u256, @intCast(context.address)));
}

fn op_balance(context: *Context) !void {
    try context.spendGas(100);
    const address = try context.stack.pop();
    const addr: u160 = @truncate(address);
    const address_state = try context.loadAddress(addr);
    try context.stack.push(address_state.balance);
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
    const i = try context.stack.pop();
    var calldata_bytes: [32]u8 = undefined;
    for (0..32) |index| {
        const src = @as(usize, @truncate(i)) + index;
        const dst = 31 - index;
        const byte = if (i + index >= context.call_data.len) 0 else context.call_data[src];
        calldata_bytes[dst] = byte;
    }
    const word: u256 = @bitCast(calldata_bytes);
    try context.stack.push(word);
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
    const dest_offset = try context.stack.pop();
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    const dynamic_cost = 3 * @divFloor(size + 31, 32);
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
    const dest_offset = try context.stack.pop();
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    const dynamic_cost = 3 * @divFloor(size + 31, 32);
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
    const address = try context.stack.pop();
    const addr: u160 = @truncate(address);
    const address_state = try context.loadAddress(addr);
    try context.stack.push(@as(u256, @intCast(address_state.code.?.len)));
}

fn op_extcodecopy(context: *Context) !void {
    try context.spendGas(100);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    const address = try context.stack.pop();
    const dest_offset = try context.stack.pop();
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    const dynamic_cost = 3 * @divFloor(size + 31, 32);
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
    const has_return_data: bool = context.child != null and (context.child.?.status == .Return or context.child.?.status == .Revert);
    const return_data_size: u256 = if (has_return_data) context.child.?.return_data.len else 0;
    try context.stack.push(return_data_size);
}

fn op_returndatacopy(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    const dest_offset = try context.stack.pop();
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    const dynamic_cost = 3 * @divFloor(size + 31, 32);
    try context.spendGas(@as(u64, @truncate(dynamic_cost)));
    while (context.memory.buffer.items.len < dest_offset + size) {
        try context.memory.expand();
    }
    const dest_start: usize = @truncate(dest_offset);
    const u_size: usize = @truncate(size);
    @memset(context.memory.buffer.items[dest_start .. dest_start + u_size], 0);
    const has_return_data: bool = context.child != null and (context.child.?.status == .Return or context.child.?.status == .Revert);
    if (has_return_data and offset < context.child.?.return_data.len) {
        const copiable_size: usize = @truncate(context.child.?.return_data.len - offset);
        const start: usize = @truncate(offset);
        @memcpy(
            context.memory.buffer.items[dest_start .. dest_start + copiable_size],
            context.child.?.return_data[start .. start + copiable_size],
        );
    }
}

fn op_extcodehash(context: *Context) !void {
    try context.spendGas(100);
    const address = try context.stack.pop();
    const addr: u160 = @truncate(address);
    _ = try context.loadAddress(addr);
    try context.stack.push(context.codeHash(addr));
}

fn op_blockhash(context: *Context) !void {
    try context.spendGas(20);
    const block_number = try context.stack.pop();
    var block_hash: u256 = 0;
    if (block_number < context.block.number and context.block.number - block_number <= 256) {
        block_hash = context.blockHash(block_number);
    }
    try context.stack.push(block_hash);
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
    const offset = try context.stack.pop();
    const memory_word = try context.memory.load(offset);
    try context.stack.push(memory_word);
}

fn op_mstore(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    const offset = try context.stack.pop();
    const value = try context.stack.pop();
    try context.memory.store(offset, value);
}

fn op_mstore8(context: *Context) !void {
    try context.spendGas(3);
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    const offset = try context.stack.pop();
    const value = try context.stack.pop();
    const b: u8 = @truncate(value);
    try context.memory.storeByte(offset, b);
}

fn op_sload(context: *Context) !void {
    try context.spendGas(100);
    const slot = try context.stack.pop();
    const value = try context.loadStorageSlot(slot);
    try context.stack.push(value);
}

fn op_sstore(context: *Context) !void {
    try context.spendGas(100);
    const slot = try context.stack.pop();
    const value = try context.stack.pop();
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
    const counter = try context.stack.pop();
    const b = try context.stack.pop();
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
    const key = try context.stack.pop();
    const address_state = try context.loadAddress(context.address);
    const word = address_state.tLoad(key);
    try context.stack.push(word);
}

fn op_tstore(context: *Context) !void {
    try context.spendGas(100);
    const key = try context.stack.pop();
    const value = try context.stack.pop();
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
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    const data = try context.memory.read(offset, size);
    defer context.memory.allocator.free(data);
    const dynamic_cost = 8 * @divFloor(size + 31, 32);
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
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    topics[0] = try context.stack.pop();
    const data = try context.memory.read(offset, size);
    defer context.memory.allocator.free(data);
    const dynamic_cost = 8 * @divFloor(size + 31, 32);
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
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    topics[0] = try context.stack.pop();
    topics[1] = try context.stack.pop();
    const data = try context.memory.read(offset, size);
    defer context.memory.allocator.free(data);
    const dynamic_cost = 8 * @divFloor(size + 31, 32);
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
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    topics[0] = try context.stack.pop();
    topics[1] = try context.stack.pop();
    topics[2] = try context.stack.pop();
    const data = try context.memory.read(offset, size);
    defer context.memory.allocator.free(data);
    const dynamic_cost = 8 * @divFloor(size + 31, 32);
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
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    topics[0] = try context.stack.pop();
    topics[1] = try context.stack.pop();
    topics[2] = try context.stack.pop();
    topics[3] = try context.stack.pop();
    const data = try context.memory.read(offset, size);
    defer context.memory.allocator.free(data);
    const dynamic_cost = 8 * @divFloor(size + 31, 32);
    try context.spendGas(@truncate(dynamic_cost));
    try context.emitLog(topics, data);
}

fn op_create(context: *Context) !void {
    try context.spendGas(32000);
    const value = try context.stack.pop();
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    _ = value;
    _ = offset;
    _ = size;
    try context.stack.push(0);
}

fn op_call(context: *Context) !void {
    try context.spendGas(100);
    const gas = try context.stack.pop();
    const address = try context.stack.pop();
    const value = try context.stack.pop();
    const args_offset = try context.stack.pop();
    const args_size = try context.stack.pop();
    const ret_offset = try context.stack.pop();
    const ret_size = try context.stack.pop();
    _ = gas;
    _ = address;
    _ = value;
    _ = args_offset;
    _ = args_size;
    _ = ret_offset;
    _ = ret_size;
    try context.stack.push(1);
}

fn op_callcode(context: *Context) !void {
    try context.spendGas(100);
    const gas = try context.stack.pop();
    const address = try context.stack.pop();
    const value = try context.stack.pop();
    const args_offset = try context.stack.pop();
    const args_size = try context.stack.pop();
    const ret_offset = try context.stack.pop();
    const ret_size = try context.stack.pop();
    _ = gas;
    _ = address;
    _ = value;
    _ = args_offset;
    _ = args_size;
    _ = ret_offset;
    _ = ret_size;
    try context.stack.push(1);
}

fn op_return(context: *Context) !void {
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    context.return_data = try context.memory.read(offset, size);
    context.status = .Return;
}

fn op_delegatecall(context: *Context) !void {
    try context.spendGas(100);
    const gas = try context.stack.pop();
    const address = try context.stack.pop();
    const args_offset = try context.stack.pop();
    const args_size = try context.stack.pop();
    const ret_offset = try context.stack.pop();
    const ret_size = try context.stack.pop();
    _ = gas;
    _ = address;
    _ = args_offset;
    _ = args_size;
    _ = ret_offset;
    _ = ret_size;
    try context.stack.push(1);
}

fn op_create2(context: *Context) !void {
    try context.spendGas(32000);
    const value = try context.stack.pop();
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    const salt = try context.stack.pop();
    _ = value;
    _ = offset;
    _ = size;
    _ = salt;
    try context.stack.push(0);
}

fn op_staticcall(context: *Context) !void {
    try context.spendGas(100);
    const gas = try context.stack.pop();
    const address = try context.stack.pop();
    const args_offset = try context.stack.pop();
    const args_size = try context.stack.pop();
    const ret_offset = try context.stack.pop();
    const ret_size = try context.stack.pop();
    _ = gas;
    _ = address;
    _ = args_offset;
    _ = args_size;
    _ = ret_offset;
    _ = ret_size;
    try context.stack.push(1);
}

fn op_revert(context: *Context) !void {
    const initial_memory_cost = context.memory.cost();
    defer {
        const new_memory_cost = context.memory.cost();
        context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
    }
    const offset = try context.stack.pop();
    const size = try context.stack.pop();
    context.return_data = try context.memory.read(offset, size);
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
