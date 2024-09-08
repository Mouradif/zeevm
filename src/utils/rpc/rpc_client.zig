const std = @import("std");
const RPCError = @import("rpc_error.zig").RPCError;
const RPCBasicResponse = @import("rpc_basic_response.zig");
const RPCParsedResponse = @import("rpc_parsed_response.zig").RPCParsedResponse;
const Hex = @import("../hex.zig");

const RPCClient = @This();

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

test "RPC Client: Get Block Number" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.blockNumber();
    try std.testing.expect(num > 0);
}

test "RPC Client: Get Chain ID" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.chainId();
    try std.testing.expectEqual(1, num);
}

test "RPC Client: Get Balance" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.getBalance(0x9eb3a30117810d5a36568714eb5350480942f644);
    try std.testing.expectEqual(989526957132020483, num);
}

test "RPC Client: Get Nonce" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.getTransactionCount(0x9eb3a30117810d5a36568714eb5350480942f644);
    try std.testing.expectEqual(454, num);
}

test "RPC Client: Get Code" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const code = try rpc_client.getCode(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640);
    defer std.testing.allocator.free(code);
}
