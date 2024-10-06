const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    const lib = b.addStaticLibrary(.{
        .name = "zee",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // Examples
    const examples_step = b.step("example", "Run example");

    const example_exe = b.addExecutable(.{
        .name = "snailtracer example",
        .root_source_file = b.path("examples/example.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zee_module = b.addModule("zee", .{
        .root_source_file = b.path("src/root.zig"),
    });

    example_exe.root_module.addImport("zee", zee_module);

    const example_run = b.addRunArtifact(example_exe);
    if (b.args) | args | {
        example_run.addArgs(args);
    }
    examples_step.dependOn(&example_run.step);
}
