const std = @import("std");
const BigInteger = @import("bigint.zig").BigInteger;

test {
    _ = @import("bigint.zig");
}

pub fn main() !void {
    const print = std.debug.print;
    const allocator = std.heap.page_allocator;

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    try stdout.print("input your number... ", .{});

    var buf = try stdin.readUntilDelimiterAlloc(allocator, '\n', 30);
    var line_buf = std.mem.trimRight(u8, buf, "\r");

    var bint1 = try BigInteger.from_string(allocator, line_buf);
    var bint2 = try BigInteger.from_string(allocator, "1234567890");
    var bint3 = try bint1.plus(bint2);
    var bint4 = try bint1.minus(bint2);

    print(
        \\hello zig!
        \\a: your input = {!s}
        \\b: my number = {!s}
        \\a + b = {!s}
        \\a - b = {!s}
    , .{ bint1.to_string(), bint2.to_string(), bint3.to_string(), bint4.to_string() });

    bint1.deinit();
    bint2.deinit();
    bint3.deinit();
}
