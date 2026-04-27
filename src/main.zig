const std = @import("std");
const lib = @import("vefi");
const config = @import("config");

const BigInteger = @import("bigint.zig").BigInteger;
const fizz_buzz = @import("fizzbuzz.zig");
const prime = @import("prime.zig");

test {
    _ = @import("bigint.zig");
}

/// デバッグログの表示を制御する。
pub const log_level: std.log.Level = .debug;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // sort
    var array: [10]usize = undefined;
    var target = lib.sort.LoggedSortTarget{ .slice = &array };

    for (0..100) |_| {
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
