const std = @import("std");
const lib = @import("ziglib");

test {
    std.testing.refAllDecls(@This());
}

const Fizz = struct {
    count: usize,
    name: []const u8,
};

const FizzOptions = struct {
    const default_fizz = [_]Fizz{
        .{ .count = 3, .name = "Fizz" },
        .{ .count = 5, .name = "Buzz" },
    };
    fizzes: []const Fizz = &default_fizz,

    separator: []const u8 = "\n",
};

/// 1からnまでのfizzbuzzを1行ずつ標準出力に書き込みます。
pub fn fizz(n: u32, writer: anytype, options: FizzOptions) !void {
    for (1..n + 1) |i| { // iを1からnまでループする
        var is_fizzed = false;
        for (options.fizzes) |f| {
            if (i % f.count == 0) {
                try writer.print("{s}", .{f.name});
                is_fizzed = true;
            }
        }
        if (!is_fizzed) {
            try writer.print("{d}", .{i});
        }

        try writer.print("{s}", .{options.separator});
    }
}
