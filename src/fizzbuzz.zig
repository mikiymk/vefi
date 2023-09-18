const std = @import("std");

pub fn fizzbuzz(n: u32) !void {
    const writer = std.io.getStdOut().writer();

    for (1..n + 1) |i| {
        if (i % 15 == 0) {
            try writer.print("FizzBuzz ", .{});
        } else if (i % 5 == 0) {
            try writer.print("Buzz ", .{});
        } else if (i % 3 == 0) {
            try writer.print("Fizz ", .{});
        } else {
            try writer.print("{d} ", .{i});
        }
    }
    try writer.print("\n", .{});
}
