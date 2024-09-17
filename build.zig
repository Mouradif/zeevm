const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // Examples
    const examples_step = b.step("example", "Run examples");

    const example = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("examples/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zee_stack_module = b.addModule("zee_stack", .{
        .root_source_file = b.path("src/lib/stack.zig"),
    });

    example.root_module.addImport("zee_stack", zee_stack_module);

    const example_run = b.addRunArtifact(example);
    examples_step.dependOn(&example_run.step);

    b.default_step.dependOn(examples_step);
}
