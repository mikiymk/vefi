const std = @import("std");

const Optimize = std.builtin.OptimizeMode;
const Build = std.Build;
const Target = std.Build.ResolvedTarget;
const Module = std.Build.Module;
const Compile = std.Build.Step.Compile;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const is_enabled = b.option(bool, "is_enabled", "Enable some capability") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "is_enabled", is_enabled);

    const exe = addExecutable(b, target, optimize);
    const lib_module = addModule(b, target, optimize);
    exe.root_module.addImport("ziglib", lib_module);

    exe.root_module.addOptions("config", options);

    addRunExe(b, exe);
    addRunUnitTest(b, target, optimize);
    addRunZigTest(b, target, optimize);
}

fn addModule(b: *Build, target: Target, optimize: Optimize) *Module {
    return b.addModule("ziglib", .{
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });
}

fn addExecutable(b: *Build, target: Target, optimize: Optimize) *Compile {
    const exe = b.addExecutable(.{
        .name = "miniature-fiesta",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    return exe;
}

fn addRunExe(b: *Build, exe: *Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn addRunUnitTest(b: *Build, target: Target, optimize: Optimize) void {
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn addRunZigTest(b: *Build, target: Target, optimize: Optimize) void {
    const zig_tests = b.addTest(.{
        .root_source_file = b.path("zig/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_zig_tests = b.addRunArtifact(zig_tests);
    const zig_test_step = b.step("test-zig", "Run zig tests");
    zig_test_step.dependOn(&run_zig_tests.step);
}
