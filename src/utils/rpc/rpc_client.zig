const std = @import("std");
const RPCError = @import("rpc_error.zig").RPCError;
const RPCBasicResponse = @import("rpc_basic_response.zig");
const RPCParsedResponse = @import("rpc_parsed_response.zig").RPCParsedResponse;
const Hex = @import("../hex.zig");
const ByteArray = @import("../../types/byte_array.zig").ByteArray;

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
    var response = ByteArray.init(self.allocator);
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
    var response = ByteArray.init(self.allocator);
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

    const num = try rpc_client.getBalance(0xcfab2d1bcdd5f8c0f4e7fdb1900550ab15df78f9);
    try std.testing.expectEqual(985988331026594, num);
}

test "RPC Client: Get Nonce" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const num = try rpc_client.getTransactionCount(0xcfab2d1bcdd5f8c0f4e7fdb1900550ab15df78f9);
    try std.testing.expectEqual(13, num);
}

test "RPC Client: Get Code" {
    var rpc_client = try RPCClient.init(std.testing.allocator, rpc);
    defer rpc_client.deinit();

    const code = try rpc_client.getCode(0xad9599131cdd44b1ef6662f8e724142d9aa464bb);
    const expectedCode = "\x36\x3d\x3d\x37\x3d\x3d\x3d\x36\x3d\x73\xd3\x32\x25\x4f\x27\x4c\xc6\x5a\xa1\x11\x78\xb7\x47\x34\xe2\x99\x2b\x8f\x34\x9e\x5a\xf4\x3d\x82\x80\x3e\x90\x3d\x91\x60\x2b\x57\xfd\x5b\xf3";
    try std.testing.expectEqual(expectedCode.len, code.len);
    for (expectedCode, code) |expectedByte, byte| {
        try std.testing.expectEqual(expectedByte, byte);
    }
    defer std.testing.allocator.free(code);
}
