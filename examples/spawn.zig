const std = @import("std");
const zee = @import("zee");

const Block = zee.Block;
const Context = zee.Context;
const ChainState = zee.ChainState;
const ContextStatus = zee.ContextStatus;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var block = Block{
        .timestamp = 666,
    };
    block.number = 32;
    var context = Context.init(allocator, .{
        .block = block,
        .state = ChainState.init(allocator),
        .gas = 100,
        .call_data = "",
    });
    defer context.deinit();
    try context.spawn(1, 0, "", 10, false);
    if (context.block.number != context.child.?.block.number) {
        std.debug.print("Block number {d} VS {d}\n", .{ context.block.number, context.child.?.block.number });
    }
    if (context.block.base_fee != context.child.?.block.base_fee) {
        std.debug.print("Base fee {d} VS {d}\n", .{ context.block.base_fee, context.child.?.block.base_fee });
    }
    if (context.block.timestamp != context.child.?.block.timestamp) {
        std.debug.print("Block timestamp {d} VS {d}\n", .{ context.block.timestamp, context.child.?.block.timestamp });
    }
    if (context.chain.id != context.child.?.chain.id) {
        std.debug.print("Chain {d} VS {d}\n", .{ context.chain.id, context.child.?.chain.id });
    }
    if (context.address != context.child.?.caller) {
        std.debug.print("Address != caller\n", .{});
    }
    if (ContextStatus.Spawn != context.status) {
        std.debug.print("Status != Spawn\n", .{});
    }
    if (ContextStatus.Continue != context.child.?.status) {
        std.debug.print("Status != Continue\n", .{});
    }
}
