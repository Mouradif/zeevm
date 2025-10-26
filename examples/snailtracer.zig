const std = @import("std");
const zee = @import("zee");

const Hex = zee.Hex;
const Context = zee.Context;
const ChainState = zee.ChainState;
const AddressState = zee.AddressState;
const ContextStatus = zee.ContextStatus;
const EVM = zee.EVM;

const starting_gas = 3_000_000_000;

pub fn main() !void {
    std.debug.print("Running snailtracer example!\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const calldata = "\x30\x62\x7b\x7c";
    const code = @embedFile("snailtracer.bc");
    var context = Context.init(allocator, .{
        .state = ChainState.init(allocator),
    });
    defer context.deinit();
    var address_state = AddressState.init(allocator, .{ .code = @constCast(code) });
    try context.state.put(1, &address_state);
    var evm = EVM.init(allocator, .{
        .context = &context,
    });
    defer evm.deinit();
    var expected_result: [96]u8 = .{0} ** 96;
    expected_result[0] = 0x19;
    expected_result[32] = 0x18;
    expected_result[64] = 0x63;

    const return_data = try evm.run(.{
        .call_data = calldata,
        .gas = starting_gas,
    });
    if (return_data) |rc| {
        std.debug.print("Return data: ", .{});
        Hex.printBytes(rc);
        std.debug.print("Gas used: {d}\n", .{starting_gas - evm.context.gas});
    }
    defer allocator.free(return_data.?);
}
