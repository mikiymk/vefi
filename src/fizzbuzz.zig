const std = @import("std");

/// 1からnまでのfizzbuzzを1行ずつ標準出力に書き込みます。
pub fn fizzbuzz(n: u32) !void {
    const writer = std.io.getStdOut().writer();

    for (1..n + 1) |i| {
        // iを1からnまでループする
        if (i % 15 == 0) {
            // iが3で割り切れてかつ5で割り切れる場合
            try writer.print("FizzBuzz\n", .{});
        } else if (i % 5 == 0) {
            // iが5で割り切れる場合
            try writer.print("Buzz\n", .{});
        } else if (i % 3 == 0) {
            // iが3で割り切れる場合
            try writer.print("Fizz\n", .{});
        } else {
            // それ以外の場合
            try writer.print("{d}\n", .{i});
        }
    }
}
