const std = @import("std");
const zee = @import("zee");

const Hex = zee.Hex;
const Context = zee.Context;
const ChainState = zee.ChainState;
const AddressState = zee.AddressState;
const ContextStatus = zee.ContextStatus;
const RPCClient = zee.RPCClient;
const EVM = zee.EVM;

pub fn main() !void {
    std.debug.print("Running replay example!\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var context = Context.init(allocator, .{});
    var evm = try EVM.fork_init(allocator, .{
        .fork_url = "http://geth.metal:10544",
        .context = &context,
    });
    std.debug.print("EVM initialized\n", .{});
    defer evm.deinit();

    const return_data = try evm.run(.{
        .call_data = "\x8d\xa5\xcb\x5b",
        .address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48,
        .gas = 50_000,
    });

    if (return_data != null) {
        allocator.free(return_data.?);
    }
}
