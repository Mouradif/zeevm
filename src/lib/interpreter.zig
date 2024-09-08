const std = @import("std");
const OpCode = @import("opcode.zig").OpCode;
const Context = @import("context.zig");
const Hash = @import("utils/hash.zig");
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
    const shift = (31 - i) * 8;
    const shifted: u256 = x >> shift;
    const byte: u8 = @truncate(shifted);
    return byte;
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

pub fn run(context: *Context, op: OpCode) !void {
    switch (op) {
        .STOP => {
            context.status = .Stop;
        },
        .ADD => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(a +% b);
            context.program_counter += 1;
        },
        .MUL => {
            try context.spendGas(5);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(a *% b);
            context.program_counter += 1;
        },
        .SUB => {
            try context.spendGas(5);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(a -% b);
            context.program_counter += 1;
        },
        .DIV => {
            try context.spendGas(5);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            const result = if (b == 0) 0 else @divFloor(a, b);
            try context.stack.push(result);
            context.program_counter += 1;
        },
        .SDIV => {
            try context.spendGas(5);
            const a: i256 = @bitCast(try context.stack.pop());
            const b: i256 = @bitCast(try context.stack.pop());
            const result = if (b == 0) 0 else @divFloor(a, b);
            try context.stack.push(result);
            context.program_counter += 1;
        },
        .MOD => {
            try context.spendGas(5);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            const result = if (b == 0) 0 else @mod(a, b);
            try context.stack.push(result);
            context.program_counter += 1;
        },
        .SMOD => {
            try context.spendGas(5);
            const a: i256 = @bitCast(try context.stack.pop());
            const b: i256 = @bitCast(try context.stack.pop());
            const result = if (b == 0) 0 else @mod(a, b);
            try context.stack.push(result);
            context.program_counter += 1;
        },
        .ADDMOD => {
            try context.spendGas(8);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            const N = try context.stack.pop();
            const result = if (N == 0) 0 else @mod(a + b, N);
            try context.stack.push(result);
            context.program_counter += 1;
        },
        .MULMOD => {
            try context.spendGas(8);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            const N = try context.stack.pop();
            const result = if (N == 0) 0 else @mod(a * b, N);
            try context.stack.push(result);
            context.program_counter += 1;
        },
        .EXP => {
            try context.spendGas(10);
            const a = try context.stack.pop();
            const exponent = try context.stack.pop();
            try context.stack.push(std.math.pow(u256, a, exponent));
            context.program_counter += 1;
        },
        .SIGNEXTEND => {
            try context.spendGas(5);
            const b = try context.stack.pop();
            const x = try context.stack.pop();
            try context.stack.push(signExtend(b, x));
            context.program_counter += 1;
        },
        .LT => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(@intFromBool(a < b));
            context.program_counter += 1;
        },
        .GT => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(@intFromBool(a > b));
            context.program_counter += 1;
        },
        .SLT => {
            try context.spendGas(3);
            const a: i256 = @bitCast(try context.stack.pop());
            const b: i256 = @bitCast(try context.stack.pop());
            try context.stack.push(@intFromBool(a < b));
            context.program_counter += 1;
        },
        .SGT => {
            try context.spendGas(3);
            const a: i256 = @bitCast(try context.stack.pop());
            const b: i256 = @bitCast(try context.stack.pop());
            try context.stack.push(@intFromBool(a > b));
            context.program_counter += 1;
        },
        .EQ => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(@intFromBool(a == b));
            context.program_counter += 1;
        },
        .ISZERO => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            try context.stack.push(@intFromBool(a == 0));
            context.program_counter += 1;
        },
        .AND => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(a & b);
            context.program_counter += 1;
        },
        .OR => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(a | b);
            context.program_counter += 1;
        },
        .XOR => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            const b = try context.stack.pop();
            try context.stack.push(a ^ b);
            context.program_counter += 1;
        },
        .NOT => {
            try context.spendGas(3);
            const a = try context.stack.pop();
            try context.stack.push(~a);
            context.program_counter += 1;
        },
        .BYTE => {
            try context.spendGas(3);
            const i = try context.stack.pop();
            const x = try context.stack.pop();
            try context.stack.push(getByte(i, x));
            context.program_counter += 1;
        },
        .SHL => {
            try context.spendGas(3);
            const shift = try context.stack.pop();
            const value = try context.stack.pop();
            try context.stack.push(leftShifted(shift, value));
            context.program_counter += 1;
        },
        .SHR => {
            try context.spendGas(3);
            const shift = try context.stack.pop();
            const value = try context.stack.pop();
            try context.stack.push(rightShifted(shift, value));
            context.program_counter += 1;
        },
        .SAR => {
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
            context.program_counter += 1;
        },
        .KECCAK256 => {
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
            try context.spendGas(dynamic_cost);
            defer context.memory.allocator.free(data);
            try context.stack.push(Hash.keccak256(data));
            context.program_counter += 1;
        },
        .ADDRESS => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.address)));
            context.program_counter += 1;
        },
        .BALANCE => {
            try context.spendGas(100);
            const address = try context.stack.pop();
            const addr: u160 = @truncate(address);
            const address_state = try context.loadAddress(addr);
            try context.stack.push(address_state.balance);
            context.program_counter += 1;
        },
        .ORIGIN => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.origin)));
            context.program_counter += 1;
        },
        .CALLER => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.caller)));
            context.program_counter += 1;
        },
        .CALLVALUE => {
            try context.spendGas(2);
            try context.stack.push(context.call_value);
            context.program_counter += 1;
        },
        .CALLDATALOAD => {
            try context.spendGas(3);
            const i = try context.stack.pop();
            var calldata_bytes: [32]u8 = undefined;
            for (0..32) |index| {
                calldata_bytes[31 - i] = if (i + index >= context.call_data.len) 0 else context.call_data[i + index];
            }
            const word: u256 = @bitCast(calldata_bytes);
            try context.stack.push(word);
            context.program_counter += 1;
        },
        .CALLDATASIZE => {
            try context.spendGas(2);
            try context.push(@as(u256, @intCast(context.call_data.len)));
            context.program_counter += 1;
        },
        .CALLDATACOPY => {
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
            try context.spendGas(dynamic_cost);
            while (context.memory.buffer.items.len < dest_offset + size) {
                try context.memory.expand();
            }
            @memset(context.memory.buffer.items[dest_offset .. dest_offset + size], 0);
            if (offset < context.call_data.len) {
                const copiable_size = context.call_data.len - offset;
                @memcpy(context.memory.buffer.items[dest_offset .. dest_offset + copiable_size], context.call_data[offset .. offset + copiable_size]);
            }
            context.program_counter += 1;
        },
        .CODESIZE => {
            try context.spendGas(2);
            const address_state = try context.loadAddress(context.address);
            try context.stack.push(@as(u256, @intCast(address_state.code.len)));
            context.program_counter += 1;
        },
        .CODECOPY => {
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
            try context.spendGas(dynamic_cost);
            const address_state = try context.loadAddress(context.address);
            while (context.memory.buffer.items.len < dest_offset + size) {
                try context.memory.expand();
            }
            @memset(context.memory.buffer.items[dest_offset .. dest_offset + size], 0);
            if (offset < address_state.code.len) {
                const copiable_size = address_state.code.len - offset;
                @memcpy(context.memory.buffer.items[dest_offset .. dest_offset + copiable_size], address_state.code[offset .. offset + copiable_size]);
            }
            context.program_counter += 1;
        },
        .GASPRICE => {
            try context.spendGas(2);
            try context.stack.push(context.block.base_fee);
            context.program_counter += 1;
        },
        .EXTCODESIZE => {
            try context.spendGas(100);
            const address = try context.stack.pop();
            const addr: u160 = @truncate(address);
            const address_state = try context.loadAddress(addr);
            try context.push(@as(u256, @intCast(address_state.code.len)));
            context.program_counter += 1;
        },
        .EXTCODECOPY => {
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
            try context.spendGas(dynamic_cost);
            const address_state = try context.loadAddress(addr);
            while (context.memory.buffer.items.len < dest_offset + size) {
                try context.memory.expand();
            }
            @memset(context.memory.buffer.items[dest_offset .. dest_offset + size], 0);
            if (offset < address_state.code.len) {
                const copiable_size = address_state.code.len - offset;
                @memcpy(context.memory.buffer.items[dest_offset .. dest_offset + copiable_size], address_state.code[offset .. offset + copiable_size]);
            }
            context.program_counter += 1;
        },
        .RETURNDATASIZE => {
            try context.spendGas(2);
            const has_return_data: bool = context.child != null and (context.child.?.status == .Return or context.child.?.status == .Revert);
            const return_data_size: u256 = if (has_return_data) context.child.?.return_data.len else 0;
            try context.stack.push(return_data_size);
            context.program_counter += 1;
        },
        .RETURNDATACOPY => {
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
            try context.spendGas(dynamic_cost);
            while (context.memory.buffer.items.len < dest_offset + size) {
                try context.memory.expand();
            }
            @memset(context.memory.buffer.items[dest_offset .. dest_offset + size], 0);
            const has_return_data: bool = context.child != null and (context.child.?.status == .Return or context.child.?.status == .Revert);
            if (has_return_data and offset < context.child.?.return_data.len) {
                const copiable_size = context.child.?.return_data.len - offset;
                @memcpy(context.memory.buffer.items[dest_offset .. dest_offset + copiable_size], address_state.code[offset .. offset + copiable_size]);
            }
            context.program_counter += 1;
        },
        .EXTCODEHASH => {
            try context.spendGas(100);
            const address = try context.stack.pop();
            const addr: u160 = @truncate(address);
            const address_state = try context.loadAddress(addr);
            try context.push(context.state.codeHash(addr));
            context.program_counter += 1;
        },
        .BLOCKHASH => {
            try context.spendGas(20);
            const block_number = context.stack.pop();
            var block_hash: u256 = 0;
            if (block_number < context.block.number and context.block.number - block_number <= 256) {
                block_hash = context.blockHash(block_number);
            }
            try context.push(block_hash);
            context.program_counter += 1;
        },
        .COINBASE => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.block.coinbase)));
            context.program_counter += 1;
        },
        .TIMESTAMP => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.block.timestamp)));
            context.program_counter += 1;
        },
        .NUMBER => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.block.number)));
            context.program_counter += 1;
        },
        .PREVRANDAO => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.block.prevrandao)));
            context.program_counter += 1;
        },
        .GASLIMIT => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.chain.gas_limit)));
            context.program_counter += 1;
        },
        .CHAINID => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.chain.id)));
            context.program_counter += 1;
        },
        .SELFBALANCE => {
            try context.spendGas(2);
            const address_state = context.loadAddress(context.address);
            try context.stack.push(address_state.balance);
            context.program_counter += 1;
        },
        .BASEFEE => {
            try context.spendGas(2);
            try context.stack.push(context.block.base_fee);
            context.program_counter += 1;
        },
        .BLOBHASH => { // @TODO implement
            try context.spendGas(3);
            try context.stack.push(0);
            context.program_counter += 1;
        },
        .BLOBBASEFEE => { // @TODO implement
            try context.spendGas(2);
            try context.stack.push(0);
            context.program_counter += 1;
        },
        .POP => {
            try context.spendGas(2);
            _ = try context.stack.pop();
            context.program_counter += 1;
        },
        .MLOAD => {
            try context.spendGas(3);
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const memory_word = try context.memory.load(offset);
            try context.stack.push(memory_word);
            context.program_counter += 1;
        },
        .MSTORE => {
            try context.spendGas(3);
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const value = try context.stack.pop();
            try context.memory.store(offset, value);
            context.program_counter += 1;
        },
        .MSTORE8 => {
            try context.spendGas(3);
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const value = try context.stack.pop();
            const byte: u8 = @truncate(value);
            try context.memory.storeByte(offset, byte);
            context.program_counter += 1;
        },
        .SLOAD => {
            try context.spendGas(100);
            const slot = try context.stack.pop();
            const value = try context.loadStorageSlot(slot);
            try context.stack.push(value);
            context.program_counter += 1;
        },
        .SSTORE => { // @TODO: Compute initialization gas cost + refunds
            try context.spendGas(100);
            const slot = try context.stack.pop();
            const value = try context.stack.pop();
            try context.writeStorageSlot(slot, value);
            context.program_counter += 1;
        },
        .JUMP => {
            try context.spendGas(8);
            const counter = try context.stack.pop();
            context.program_counter = counter;
        },
        .JUMPI => {
            try context.spendGas(10);
            const counter = try context.stack.pop();
            const b = try context.stack.pop();
            if (b == 0) {
                context.program_counter += 1;
            } else {
                context.program_counter = b;
            }
        },
        .PC => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.program_counter)));
            context.program_counter += 1;
        },
        .MSIZE => {
            try context.spendGas(2);
            const memory_size: u256 = @intCast(context.memory.buffer.items.len);
            try context.stack.push(memory_size);
            context.program_counter += 1;
        },
        .GAS => {
            try context.spendGas(2);
            try context.stack.push(@as(u256, @intCast(context.gas)));
            context.program_counter += 1;
        },
        .JUMPDEST => {
            try context.spendGas(1);
            context.program_counter += 1;
        },
        .TLOAD => {
            try context.spendGas(100);
            const key = try context.stack.pop();
            const address_state = try context.loadAddress(context.address);
            const word = address_state.tLoad(key);
            try context.stack.push(word);
        },
        .TSTORE => {
            try context.spendGas(100);
            const key = try context.stack.pop();
            const value = try context.stack.pop();
            const address_state = try context.loadAddress(context.address);
            address_state.tStore(key, value);
        },
        .MCOPY => {},
        .PUSH0 => {
            try context.spendGas(2);
            try context.push(0);
            context.program_counter += 1;
        },
        .PUSH1 => try context.push(1),
        .PUSH2 => try context.push(2),
        .PUSH3 => try context.push(3),
        .PUSH4 => try context.push(4),
        .PUSH5 => try context.push(5),
        .PUSH6 => try context.push(6),
        .PUSH7 => try context.push(7),
        .PUSH8 => try context.push(8),
        .PUSH9 => try context.push(9),
        .PUSH10 => try context.push(10),
        .PUSH11 => try context.push(11),
        .PUSH12 => try context.push(12),
        .PUSH13 => try context.push(13),
        .PUSH14 => try context.push(14),
        .PUSH15 => try context.push(15),
        .PUSH16 => try context.push(16),
        .PUSH17 => try context.push(17),
        .PUSH18 => try context.push(18),
        .PUSH19 => try context.push(19),
        .PUSH20 => try context.push(20),
        .PUSH21 => try context.push(21),
        .PUSH22 => try context.push(22),
        .PUSH23 => try context.push(23),
        .PUSH24 => try context.push(24),
        .PUSH25 => try context.push(25),
        .PUSH26 => try context.push(26),
        .PUSH27 => try context.push(27),
        .PUSH28 => try context.push(28),
        .PUSH29 => try context.push(29),
        .PUSH30 => try context.push(30),
        .PUSH31 => try context.push(31),
        .PUSH32 => try context.push(32),
        .DUP1 => try context.dup(1),
        .DUP2 => try context.dup(2),
        .DUP3 => try context.dup(3),
        .DUP4 => try context.dup(4),
        .DUP5 => try context.dup(5),
        .DUP6 => try context.dup(6),
        .DUP7 => try context.dup(7),
        .DUP8 => try context.dup(8),
        .DUP9 => try context.dup(9),
        .DUP10 => try context.dup(10),
        .DUP11 => try context.dup(11),
        .DUP12 => try context.dup(12),
        .DUP13 => try context.dup(13),
        .DUP14 => try context.dup(14),
        .DUP15 => try context.dup(15),
        .DUP16 => try context.dup(16),
        .SWAP1 => try context.swap(1),
        .SWAP2 => try context.swap(2),
        .SWAP3 => try context.swap(3),
        .SWAP4 => try context.swap(4),
        .SWAP5 => try context.swap(5),
        .SWAP6 => try context.swap(6),
        .SWAP7 => try context.swap(7),
        .SWAP8 => try context.swap(8),
        .SWAP9 => try context.swap(9),
        .SWAP10 => try context.swap(10),
        .SWAP11 => try context.swap(11),
        .SWAP12 => try context.swap(12),
        .SWAP13 => try context.swap(13),
        .SWAP14 => try context.swap(14),
        .SWAP15 => try context.swap(15),
        .SWAP16 => try context.swap(16),
        .LOG0 => { // @TODO: implement log
            try context.spendGas(375);
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const size = try context.stack.pop();
            const data = try context.memory.read(offset, length);
            defer context.memory.allocator.free(data);
            const dynamic_cost = 8 * @divFloor(size + 31, 32);
            try context.spendGas(dynamic_cost);
            std.debug.print("Log:\n  - {x:0>2}", .{data});
            self.program_counter += 1;
        },
        .LOG1 => {
            try context.spendGas(750);
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const size = try context.stack.pop();
            const topic0 = try context.stack.pop();
            const data = try context.memory.read(offset, length);
            defer context.memory.allocator.free(data);
            const dynamic_cost = 8 * @divFloor(size + 31, 32);
            try context.spendGas(dynamic_cost);
            std.debug.print("Log(0x{x:0>64}):\n  - {x:0>2}", .{ topic0, data });
            self.program_counter += 1;
        },
        .LOG2 => {
            try context.spendGas(1125);
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const size = try context.stack.pop();
            const topic0 = try context.stack.pop();
            const topic1 = try context.stack.pop();
            const data = try context.memory.read(offset, length);
            defer context.memory.allocator.free(data);
            const dynamic_cost = 8 * @divFloor(size + 31, 32);
            try context.spendGas(dynamic_cost);
            self.program_counter += 1;
            std.debug.print("Log(\n  0x{x:0>64},\n  0x{x:0>64},\n):\n  - {x:0>2}", .{ topic0, topic1, data });
        },
        .LOG3 => {
            try context.spendGas(1500);
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const size = try context.stack.pop();
            const topic0 = try context.stack.pop();
            const topic1 = try context.stack.pop();
            const topic2 = try context.stack.pop();
            const data = try context.memory.read(offset, length);
            defer context.memory.allocator.free(data);
            const dynamic_cost = 8 * @divFloor(size + 31, 32);
            try context.spendGas(dynamic_cost);
            self.program_counter += 1;
            std.debug.print("Log(\n  0x{x:0>64},\n  0x{x:0>64},\n  0x{x:0>64},\n):\n  - {x:0>2}", .{ topic0, topic1, topic2, data });
        },
        .LOG4 => {
            try context.spendGas(1875);
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const size = try context.stack.pop();
            const topic0 = try context.stack.pop();
            const topic1 = try context.stack.pop();
            const topic2 = try context.stack.pop();
            const topic3 = try context.stack.pop();
            const data = try context.memory.read(offset, length);
            defer context.memory.allocator.free(data);
            const dynamic_cost = 8 * @divFloor(size + 31, 32);
            try context.spendGas(dynamic_cost);
            self.program_counter += 1;
            std.debug.print("Log(\n  0x{x:0>64},\n  0x{x:0>64},\n  0x{x:0>64},\n  0x{x:0>64},\n):\n  - {x:0>2}", .{ topic0, topic1, topic2, topic3, data });
        },
        .CREATE => { // @TODO
            try context.spendGas(32000);
            const value = try context.pop();
            const offset = try context.pop();
            const size = try context.pop();
            _ = value;
            _ = offset;
            _ = size;
            try context.stack.push(0);
            self.program_counter += 1;
        },
        .CALL => { // @TODO
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
            self.program_counter += 1;
        },
        .CALLCODE => {
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
            self.program_counter += 1;
        },
        .RETURN => {
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const size = try context.stack.pop();
            context.return_data = context.memory.read(offset, size);
            context.status = .Return;
        },
        .DELEGATECALL => {
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
            self.program_counter += 1;
        },
        .CREATE2 => {
            try context.spendGas(32000);
            const value = try context.pop();
            const offset = try context.pop();
            const size = try context.pop();
            const salt = try context.pop();
            _ = value;
            _ = offset;
            _ = size;
            _ = salt;
            try context.stack.push(0);
            self.program_counter += 1;
        },
        .STATICCALL => {
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
            self.program_counter += 1;
        },
        .REVERT => {
            const initial_memory_cost = context.memory.cost();
            defer {
                const new_memory_cost = context.memory.cost();
                context.memory_expansion_cost = new_memory_cost - initial_memory_cost;
            }
            const offset = try context.stack.pop();
            const size = try context.stack.pop();
            context.return_data = context.memory.read(offset, size);
            context.status = .Revert;
        },
        .INVALID => {
            try context.spendGas(context.gas);
            context.status = .Panic;
        },
        .SELFDESTRUCT => {
            try context.spendGas(5000);
            const address = try context.stack.pop();
            _ = address;
            context.status = .Stop;
        },
    }
}