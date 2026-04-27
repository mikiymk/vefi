const std = @import("std");
const lib = @import("vefi");
const config = @import("config");

const BigInteger = @import("bigint.zig").BigInteger;
const fizz_buzz = @import("fizzbuzz.zig");
const prime = @import("prime.zig");

const Allocator = std.mem.Allocator;

test {
    _ = @import("bigint.zig");
}

pub const std_options = std.Options{
    // デバッグログの表示を制御する。
    .log_level = .info,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // try sortLogging(allocator);
    try lib.sort.testSorts(allocator);
}

const LoggedSortTarget = lib.sort.LoggedSortTarget;
fn sortLogging(allocator: Allocator) !void {
    var target = LoggedSortTarget{};
    try target.resize(allocator, 10);

    for (0..10) |_| {
        target.reset(.shuffle);
        std.debug.print("ソート開始 {any}\n", .{target.slice});
        try lib.sort.smoothSort2(allocator, &target);
        std.debug.print("ソート終了 {any} ", .{target.slice});
        if (target.isSorted()) {
            std.debug.print("ソート成功\n", .{});
        } else {
            std.debug.print("ソート失敗\n", .{});
            return;
        }
    }
}
