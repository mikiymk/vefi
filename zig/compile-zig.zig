const std = @import("std");
const File = std.fs.File;
const Allocator = std.mem.Allocator;
const Term = std.process.Child.Term;

pub const CompileResult = enum {
    success,
    fail,
};

pub fn compileZig(allocator: Allocator, code: []const u8) !CompileResult {
    const path = createPath(allocator);
    defer allocator.free(path);

    const file = try createFile(path);
    try file.writeAll(code);
    defer deleteFile(path);

    const term = try build(path, allocator);

    return switch (term) {
        .Exited => |n| if (n == 0) .success else .fail,
        else => .fail,
    };
}

var rng = std.Random.Xoshiro256.init(5);
const random = rng.random();
fn createPath(allocator: Allocator) []const u8 {
    const r = random.int(u64);
    return std.fmt.allocPrint(allocator, "./tmp/{x:0>16}.zig", .{r}) catch unreachable;
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

fn build(name: []const u8, allocator: Allocator) !Term {
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
    process.stdout_behavior = .Ignore;
    process.stderr_behavior = .Ignore;
    return process.spawnAndWait();
}

test {
    const utils = @import("./utils.zig");

    try utils.assert(try compileZig(utils.allocator, "pub fn main() void {}") == .success);
}
