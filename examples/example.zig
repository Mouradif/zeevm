const std = @import("std");
const snailtracer = @import("./snailtracer.zig");
const replay = @import("./replay.zig");
const eq = std.mem.eql;

const ExampleProgram = *const fn (std.Io) anyerror!void;

fn getExample(example_name: []const u8) ?ExampleProgram {
    if (eq(u8, "snailtracer", example_name)) return snailtracer.main;
    if (eq(u8, "replay", example_name)) return replay.main;
    return null;
}

fn runExample(io: std.Io, example_name: []const u8) !void {
    const example = getExample(example_name);
    if (example) | program | {
        try program(io);
    } else {
        std.debug.print("Unknown example file {s}\n", .{example_name});
    }
}

pub fn main(init: std.process.Init) !void {
    var args = init.minimal.args.iterate();
    _ = args.skip();

    const arg = args.next();
    if (arg) |example_name| {
        try runExample(init.io, example_name);
    } else {
        std.debug.print("Usage: zig build example -- <example-name>\n\n", .{});
        std.debug.print("Available examples:\n", .{});
        std.debug.print("  - {s}\n", .{"snailtracer"});
        std.debug.print("  - {s}\n\n", .{"replay"});
    }
}
