//! ユーティリティ関数群

const std = @import("std");
const File = std.fs.File;
const Allocator = std.mem.Allocator;
const Term = std.process.Child.Term;

/// 使用しない変数を使用するための関数
pub fn consume(_: anytype) void {}

/// valueがtrueであることを確認します。
pub fn assert(value: bool) !void {
    if (!value) {
        return error.AssertionFailed;
    }
}

/// 2つのスライスを等値比較します。
pub fn equalSlices(left: anytype, right: @TypeOf(left)) bool {
    return left.len == right.len and for (left, right) |l, r| {
        if (l != r) break false;
    } else true;
}

/// 2つの値を近似比較します。
pub fn equalApprox(left: anytype, right: @TypeOf(left), tolerance: @TypeOf(left)) bool {
    return @abs(left - right) < tolerance;
}

pub const CompileResult = enum {
    success,
    fail,
};
const allocator = std.testing.allocator;

pub fn compileZig(code: []const u8) !CompileResult {
    const path = "./tmp/main.zig";

    const file = try createFile(path);
    try file.writeAll("pub fn main() void {}\n");
    try file.writeAll(code);
    defer deleteFile(path);

    const term = try build(path);

    return switch (term) {
        .Exited => |n| if (n == 0) .success else .fail,
        else => .fail,
    };
}

fn deleteFile(name: []const u8) void {
    const dir = std.fs.cwd();
    dir.deleteFile(name) catch return;
}

fn createFile(name: []const u8) !File {
    const dir = std.fs.cwd();
    _ = dir.openDir("tmp", .{}) catch |err| switch (err) {
        // なかったら作る
        error.FileNotFound => try dir.makeDir("tmp"),
        else => |e| return e,
    };

    const file = dir.openFile(name, .{ .mode = .write_only }) catch |err| switch (err) {
        // なかったら作る
        error.FileNotFound => try dir.createFile(name, .{}),
        else => |e| return e,
    };
    // ファイルを空にする
    try file.setEndPos(0);

    return file;
}

fn build(name: []const u8) !Term {
    var process = std.process.Child.init(&.{
        "zig",
        "build-exe",
        name,
        // 何も出力しない
        "-fno-emit-bin",
        "-fno-emit-asm",
        "-fno-emit-llvm-ir",
        "-fno-emit-llvm-bc",
        "-fno-emit-h",
        "-fno-emit-docs",
        "-fno-emit-implib",
    }, allocator);
    // process.stdout_behavior = .Ignore;
    // process.stderr_behavior = .Ignore;
    return process.spawnAndWait();
}
