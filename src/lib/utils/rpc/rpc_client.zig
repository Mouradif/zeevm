const std = @import("std");
const RPCError = @import("rpc_error.zig").RPCError;
const RPCBasicResponse = @import("rpc_basic_response.zig");
const RPCParsedResponse = @import("rpc_parsed_response.zig").RPCParsedResponse;

const RPCClient = @This();

const Hex = struct {
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
        const a: u8 = parseHexDigit(high) << 4;
        const b: u8 = parseHexDigit(low);
        return a | b;
    }

    pub fn parseStaticBuffer(input: []const u8, length: usize, buffer: []u8) void {
        const start: usize = if (input.len > 1 and input[1] == 'x') 2 else 0;
        const leading_zero = @mod(input.len, 2);
        const byteLength = @divFloor(input.len - start + leading_zero, 2);
        const leading_zero_bytes = length - byteLength;

        var i: usize = 0;
        var j: usize = 0;
        while (i < length) : (i += 1) {
            if (i < leading_zero_bytes) {
                buffer[i] = 0;
                continue;
            }
            if (j == 0 and leading_zero == 1) {
                buffer[i] = parseHexByte('0', input[j + start]);
                j += 1;
                continue;
            }
            const c1 = input[j + start];
            const c2 = input[j + start + 1];
            buffer[i] = parseHexByte(c1, c2);
            j += 2;
        }
    }

    pub fn parseUint(allocator: std.mem.Allocator, input: []const u8, T: type) !T {
        const byteSize = @divFloor(@bitSizeOf(T), 8);
        const buffer: []u8 = try allocator.alloc(u8, byteSize);
        defer allocator.free(buffer);
        parseStaticBuffer(input, byteSize, buffer);
        return @byteSwap(@as(T, @bitCast(@as([byteSize]u8, buffer[0..byteSize].*))));
    }
};

allocator: std.mem.Allocator,
http_client: std.http.Client,
rpc_uri: std.Uri,

pub fn init(allocator: std.mem.Allocator, url: []const u8) !RPCClient {
    return .{
        .allocator = allocator,
        .http_client = std.http.Client{ .allocator = allocator },
        .rpc_uri = try std.Uri.parse(url),
    };
}

pub fn deinit(self: *RPCClient) void {
    self.http_client.deinit();
}

pub fn blobBaseFee(self: *RPCClient) !u64 {
    return self.makeBasicNumericRPCRequest("eth_blobBaseFee", u64);
}

pub fn blockNumber(self: *RPCClient) !u64 {
    return self.makeBasicNumericRPCRequest("eth_blockNumber", u64);
}

pub fn chainId(self: *RPCClient) !u64 {
    return self.makeBasicNumericRPCRequest("eth_chainId", u64);
}

pub fn gasPrice(self: *RPCClient) !u64 {
    return self.makeBasicNumericRPCRequest("eth_gasPrice", u64);
}

pub fn getBalance(self: *RPCClient, address: u160) !u256 {
    return self.makeAddressNumericRPCRequest("eth_getBalance", address, u256);
}

pub fn getTransactionCount(self: *RPCClient, address: u160) !u256 {
    return self.makeAddressNumericRPCRequest("eth_getTransactionCount", address, u256);
}

pub fn getCode(self: *RPCClient, address: u160) ![]u8 {
    var parsed_response = try self.makeAddressRPCRequest("eth_getCode", address);
    defer parsed_response.deinit();
    const code_response = parsed_response.parsed.value.result;
    const length = @divFloor(code_response.len - 2, 2);
    const code = try self.allocator.alloc(u8, length);
    Hex.parseStaticBuffer(code_response, length, code);
    return code;
}

fn makeBasicNumericRPCRequest(self: *RPCClient, req: []const u8, T: type) !T {
    var parsed_response = try self.makeBasicRPCRequest(req);
    defer parsed_response.deinit();
    return try Hex.parseUint(self.allocator, parsed_response.parsed.value.result, T);
}

fn makeAddressNumericRPCRequest(self: *RPCClient, req: []const u8, address: u160, T: type) !T {
    var parsed_response = try self.makeAddressRPCRequest(req, address);
    defer parsed_response.deinit();
    return try Hex.parseUint(self.allocator, parsed_response.parsed.value.result, T);
}

fn makeBasicRPCRequest(self: *RPCClient, req: []const u8) !RPCParsedResponse(RPCBasicResponse) {
    var response = std.ArrayList(u8).init(self.allocator);
    defer response.deinit();
    const payload = try std.fmt.allocPrint(
        self.allocator,
        "{{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"{s}\",\"params\":[]}}",
        .{req},
    );
    defer self.allocator.free(payload);
    const result = try self.http_client.fetch(.{
        .headers = .{ .content_type = .{ .override = "application/json" } },
        .payload = payload,
        .method = .POST,
        .location = .{ .uri = self.rpc_uri },
        .response_storage = .{ .dynamic = &response },
    });
    if (result.status != .ok) {
        return RPCError.RequestFailed;
    }
    const response_body = try response.toOwnedSlice();
    const parsed = try std.json.parseFromSlice(
        RPCBasicResponse,
        self.allocator,
        response_body,
        .{ .ignore_unknown_fields = true },
    );
    return .{
        .allocator = self.allocator,
        .parsed = parsed,
        .buffer = response_body,
    };
}

fn makeAddressRPCRequest(self: *RPCClient, req: []const u8, address: u160) !RPCParsedResponse(RPCBasicResponse) {
    var response = std.ArrayList(u8).init(self.allocator);
    defer response.deinit();
    const payload = try std.fmt.allocPrint(
        self.allocator,
        "{{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"{s}\",\"params\":[\"0x{x:0>40}\",\"latest\"]}}",
        .{ req, address },
    );
    defer self.allocator.free(payload);
    const result = try self.http_client.fetch(.{
        .headers = .{ .content_type = .{ .override = "application/json" } },
        .payload = payload,
        .method = .POST,
        .location = .{ .uri = self.rpc_uri },
        .response_storage = .{ .dynamic = &response },
    });
    if (result.status != .ok) {
        return RPCError.RequestFailed;
    }
    const response_body = try response.toOwnedSlice();
    const parsed = try std.json.parseFromSlice(
        RPCBasicResponse,
        self.allocator,
        response_body,
        .{ .ignore_unknown_fields = true },
    );
    return .{
        .allocator = self.allocator,
        .parsed = parsed,
        .buffer = response_body,
    };
}

const rpc = "http://geth.metal:10545";

test "Get Block Number" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.blockNumber();
    try std.testing.expect(num > 0);
}

test "Get Chain ID" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.chainId();
    try std.testing.expectEqual(1, num);
}

test "Get Balance" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.getBalance(0x9eb3a30117810d5a36568714eb5350480942f644);
    try std.testing.expectEqual(989526957132020483, num);
}

test "Get Nonce" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.getTransactionCount(0x9eb3a30117810d5a36568714eb5350480942f644);
    try std.testing.expectEqual(454, num);
}

test "Get Code" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const code = try rpc_client.getCode(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640);
    defer std.testing.allocator.free(code);
}
