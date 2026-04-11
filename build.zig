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

    // モジュールを作成
    const lib_module = b.addModule("vefi", .{
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
    });

    // 実行ファイルを作成
    const exe = b.addExecutable(.{
        .name = "vefi",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    // 実行する
    exe.root_module.addImport("vefi", lib_module);
    exe.root_module.addOptions("config", options);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // テストを実行
    const mod_tests = b.addTest(.{
        .root_module = lib_module,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_tests.step);

    // Zigのテストを実行
    const zig_tests_mod = b.addModule("zig-test", .{
        .root_source_file = b.path("zig/root.zig"),
        .target = target,
    });
    const zig_tests = b.addTest(.{
        .root_module = zig_tests_mod,
    });
    const run_zig_tests = b.addRunArtifact(zig_tests);
    const zig_test_step = b.step("test-zig", "Run zig tests");
    zig_test_step.dependOn(&run_zig_tests.step);
}
