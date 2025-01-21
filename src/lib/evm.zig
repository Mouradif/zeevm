const std = @import("std");
const config = @import("config");

const Block = @import("../types/block.zig");
const Chain = @import("../types/chain.zig");
const Hex = @import("../utils/hex.zig");
const ChainState = @import("../types/chain_state.zig").ChainState;
const ContextStatus = @import("../types/context_status.zig").ContextStatus;
const AddressAccesslist = @import("../types/address_accesslist.zig").AddressAccesslist;
const debugLogEmitter = @import("../utils/log/debug_log_emitter.zig").debugLogEmitter;

const Context = @import("context.zig");
const AddressState = @import("address_state.zig");
const Memory = @import("memory.zig");
const RPCClient = @import("../utils/rpc/rpc_client.zig");

const EVM = @This();

const EVMInitializer = struct {
    context: *Context,
};

const EVMForkInitializer = struct {
    fork_url: []const u8,
    fork_block: u64 = 0,
    context: *Context,
};

const EVMRunParams = struct {
    caller: u160 = 2,
    origin: u160 = 2,
    address: u160 = 1,
    call_value: u256 = 0,
    gas: u64 = 30_000_000,
    call_data: []const u8 = "",
};

allocator: std.mem.Allocator,
context: *Context,
rpc_client: ?RPCClient = null,
fork_url: ?[]const u8,
fork_block: u64,

pub fn init(allocator: std.mem.Allocator, initializer: EVMInitializer) EVM {
    return .{
        .allocator = allocator,
        .context = initializer.context,
        .fork_url = null,
        .fork_block = 0,
    };
}

pub fn fork_init(allocator: std.mem.Allocator, initializer: EVMForkInitializer) !EVM {
    var client = try RPCClient.init(allocator, initializer.fork_url);
    var block = Block{};
    block.number = if (initializer.fork_block == 0) try client.blockNumber() else initializer.fork_block;
    var chain = Chain{};
    chain.id = try client.chainId();
    initializer.context.update(.{
        .chain = chain,
        .block= block,
        .rpc_client = &client,
    });
    return .{
        .allocator = allocator,
        .context = initializer.context,
        .rpc_client = client,
        .fork_url = initializer.fork_url,
        .fork_block = block.number,
    };
}

pub fn deinit(self: *EVM) void {
    if (self.rpc_client == null) return;

    self.rpc_client.?.deinit();
}

pub fn initForkedContext(self: *EVM) !void {
    var client = self.rpc_client.?;
    const address = self.context.address;
    const code = try client.getCode(address);
    std.debug.print("Found code for address {x}\n\n{}\n\n", .{address, std.fmt.fmtSliceHexLower(code)});
    if (self.context.state.get(address)) |address_state| {
        address_state.code = code;
        return;
    }
    var address_state = AddressState.init(
        self.allocator,
        .{
            .balance = try client.getBalance(address),
            .nonce = try client.getTransactionCount(address),
            .code = code,
        },
    );
    try self.context.state.put(address, &address_state);
}

pub fn run(self: *EVM, run_params: EVMRunParams) !?[]u8 {
    self.context.address = run_params.address;
    self.context.caller = run_params.caller;
    self.context.origin = run_params.origin;
    self.context.call_value = run_params.call_value;
    self.context.call_data = run_params.call_data;
    self.context.gas = run_params.gas;
    try self.context.spendCalldataGas();

    if (self.rpc_client != null) {
        try self.initForkedContext();
    }

    const address_state = self.context.state.get(self.context.address).?;
    address_state.is_warm = true;
    try self.context.address_accesslist.put(self.context.address, {});
    var timer: anyerror!std.time.Timer = undefined;

    if (config.bench) {
        timer = try std.time.Timer.start();
    }
    while (self.context.status == .Continue) {
        try self.context.runNextOperation();
        if (self.context.status == .Spawn) {
            self.context = self.context.child.?;
        }
        if (self.context.parent != null and self.context.status != .Continue) {
            const parent = self.context.parent.?;
            const success: u1 = @intFromBool(
                self.context.status == .Return or
                self.context.status == .Stop
            );
            try parent.stack.push(success);
            if (
                parent.call_result_length > 0 and (
                    self.context.status == .Return or
                    self.context.status == .Revert
                )
            ) {
                try parent.memory.apply(
                    self.context.return_data,
                    parent.call_result_offset,
                    parent.call_result_length
                );
            }
            try parent.spendGas(parent.call_gas - self.context.gas);
            self.context = parent;
            self.context.status = .Continue;
        }
    }
    if (config.bench) {
        std.debug.print("elapsed: {d}ms\n", .{@as(f64, @floatFromInt(timer.read())) / 1000000});
    }
    return self.context.return_data;
}

fn testRevertsOneWord(code_string: []const u8, expected_revert: u256, expected_gas_usage: u64) !void {
    try testRevertsOneWordWithCalldata(code_string, "", expected_revert, expected_gas_usage);
}

fn testReturnsOneWord(code_string: []const u8, expected_return: u256, expected_gas_usage: u64) !void {
    try testReturnsOneWordWithCalldata(code_string, "", expected_return, expected_gas_usage);
}

fn testReturnsOneWordWithCalldata(code_string: []const u8, calldata_string: []const u8, expected_return: u256, expected_gas_usage: u64) !void {
    try testOneWordOutput(code_string, calldata_string, expected_return, expected_gas_usage, .Return);
}

fn testRevertsOneWordWithCalldata(code_string: []const u8, calldata_string: []const u8, expected_revert: u256, expected_gas_usage: u64) !void {
    try testOneWordOutput(code_string, calldata_string, expected_revert, expected_gas_usage, .Revert);
}

fn testOneWordOutput(code_string: []const u8, calldata_string: []const u8, expected_return: u256, expected_gas_usage: u64, expected_status: ContextStatus) !void {
    const test_result = try testSingleContractCall(code_string, calldata_string);
    defer std.testing.allocator.free(test_result.return_data.?);

    try std.testing.expectEqual(32, test_result.return_data.?.len);
    var word: [32]u8 = undefined;
    @memcpy(word[0..32], test_result.return_data.?);
    const result = @byteSwap(@as(u256, @bitCast(word)));
    try std.testing.expectEqual(expected_return, result);
    try std.testing.expectEqual(expected_gas_usage, test_result.gas_used);
    try std.testing.expectEqual(expected_status, test_result.return_status);
}

fn testSingleContractCall(code_string: []const u8, calldata_string: []const u8) !struct {
    return_status: ContextStatus,
    return_data: ?[]u8,
    gas_used: u64,
} {
    const code_len = code_string.len / 2;
    const code = try std.testing.allocator.alloc(u8, code_len);
    defer std.testing.allocator.free(code);
    Hex.parseStaticBuffer(code_string, code_len, code);
    const calldata_len = calldata_string.len / 2;
    const calldata = try std.testing.allocator.alloc(u8, calldata_len);
    defer std.testing.allocator.free(calldata);
    Hex.parseStaticBuffer(calldata_string, calldata_len, calldata);
    var context = Context.init(std.testing.allocator, .{
        .state = ChainState.init(std.testing.allocator),
    });
    defer context.deinit();
    var address_state = AddressState.init(std.testing.allocator, .{ .code = code });
    try context.state.put(1, &address_state);
    var evm = EVM.init(std.testing.allocator, .{
        .context = &context,
    });
    defer evm.deinit();
    const return_data = try evm.run(.{
        .call_data = calldata,
        .gas = 30_000_000_000,
    });
    const gas_used = 30_000_000_000 - evm.context.gas;
    const return_status = evm.context.status;
    return .{
        .return_status = return_status,
        .return_data = return_data,
        .gas_used = gas_used,
    };
}

test "EVM: The meaning of life" {
    try testReturnsOneWord("602a60005260206000F3", 42, 21018);
}

test "EVM: Simple addition" {
    try testReturnsOneWord("60016004015f5260205ff3", 5, 21022);
}

test "EVM: Arithmetics" {
    try testReturnsOneWord("60068061060061420004600a0202015f5260205ff3", 666, 21046);
}

test "EVM: Control Flow" {
    try testReturnsOneWord("5f5b60010180600a116001575f5260205ff3", 10, 21305);
}

test "EVM: Solidity loop" {
    try testReturnsOneWord("6080604052348015600e575f80fd5b505f3660605f805b600a8110156036578082602891906099565b915080806001019150506016565b50806040516020016046919060d2565b604051602081830303815290604052915050915050805190602001f35b5f819050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f60a1826063565b915060aa836063565b925082820190508082111560bf5760be606c565b5b92915050565b60cc816063565b82525050565b5f60208201905060e35f83018460c5565b9291505056fea2646970667358221220fa8b7f4c3b6dcd9b6d4243a10fdab58bb71c6bfb5a5928bb5bae3495b6724f5564736f6c634300081a0033", 45, 23808);
}

test "EVM: Basic Revert" {
    try testRevertsOneWord("60205f60205f52fd", 32, 21016);
}

test "EVM: Fibonacci" {
    const code_string = "608060405234801561000f575f5ffd5b5060043610610029575f3560e01c8063c6c2ea171461002d575b5f5ffd5b610047600480360381019061004291906100f2565b61005d565b604051610054919061012c565b60405180910390f35b5f6100678261006e565b9050919050565b5f6001821161007f578190506100b6565b61009460028361008f9190610172565b61006e565b6100a96001846100a49190610172565b61006e565b6100b391906101a5565b90505b919050565b5f5ffd5b5f819050919050565b6100d1816100bf565b81146100db575f5ffd5b50565b5f813590506100ec816100c8565b92915050565b5f60208284031215610107576101066100bb565b5b5f610114848285016100de565b91505092915050565b610126816100bf565b82525050565b5f60208201905061013f5f83018461011d565b92915050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f61017c826100bf565b9150610187836100bf565b925082820390508181111561019f5761019e610145565b5b92915050565b5f6101af826100bf565b91506101ba836100bf565b92508282019050808211156101d2576101d1610145565b5b9291505056fea26469706673582212208da7bfb7187549c7610f6ee11db56adba34a41796a64b8e346393bb6d09f3c0f64736f6c634300081b0033";
    try testReturnsOneWordWithCalldata(code_string, "c6c2ea170000000000000000000000000000000000000000000000000000000000000005", 5, 26730);
}

test "EVM: Call" {
    const code_a = try std.testing.allocator.alloc(u8, 10);
    defer std.testing.allocator.free(code_a);
    const code_b = try std.testing.allocator.alloc(u8, 14);
    defer std.testing.allocator.free(code_b);
    Hex.parseStaticBuffer("604260005260206000f3", 10, code_a);
    Hex.parseStaticBuffer("60205f5f5f5f600a5af160205ff3", 14, code_b);
    var context = Context.init(std.testing.allocator, .{
        .state = ChainState.init(std.testing.allocator),
    });
    defer context.deinit();
    var address_state_a = AddressState.init(std.testing.allocator, .{ .code = code_a });
    var address_state_b = AddressState.init(std.testing.allocator, .{ .code = code_b });
    try context.state.put(0xa, &address_state_a);
    try context.state.put(0xb, &address_state_b);
    var evm = EVM.init(std.testing.allocator, .{
        .context = &context,
    });
    defer evm.deinit();
    const return_data = try evm.run(.{
        .gas = 30_000_000_000,
        .address = 0xb,
    });
    defer std.testing.allocator.free(return_data.?);
    const gas_used = 30_000_000_000 - evm.context.gas;
    try std.testing.expectEqual(21139, gas_used);
    try std.testing.expectEqual(0x42, return_data.?[31]);
}
