const std = @import("std");
const snailtracer = @import("./snailtracer.zig");
const replay = @import("./replay.zig");
const eq = std.mem.eql;

const ExampleProgram = *const fn () anyerror!void;

fn getExample(example_name: []const u8) ?ExampleProgram {
    if (eq(u8, "snailtracer", example_name)) return snailtracer.main;
    if (eq(u8, "replay", example_name)) return replay.main;
    return null;
}

fn runExample(example_name: []const u8) !void {
    const example = getExample(example_name);
    if (example) | program | {
        try program();
    } else {
        std.debug.print("Unknown example file {s}\n", .{example_name});
    }
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();

    const arg = args.next();
    if (arg) |example_name| {
        try runExample(example_name);
    } else {
        std.debug.print("Usage: zig build example -- <example-name>\n\n", .{});
        std.debug.print("Available examples:\n", .{});
        std.debug.print("  - {s}\n", .{"snailtracer"});
        std.debug.print("  - {s}\n\n", .{"replay"});
    }
}
