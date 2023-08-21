const std = @import("std");
const BigInteger = @import("bigint.zig").BigInteger;

test {
    _ = @import("bigint.zig");
}

pub fn main() !void {
    const print = std.debug.print;
    const allocator = std.heap.page_allocator;

    const stdin = std.io.getStdIn().reader();

    print("input your number... ", .{});
    var buf = try stdin.readUntilDelimiterAlloc(allocator, '\n', 280);
    var line_buf = std.mem.trimRight(u8, buf, "\r");

    print("hello zig!\n", .{});

    var bint1 = try BigInteger.from_string(allocator, line_buf);

    print("a: your input = {!s}\n", .{bint1.to_string()});

    var bint2 = try BigInteger.from_int(u32, allocator, 1234567890);

    print("b: my number = {!s}\n", .{bint2.to_string()});

    var bint3 = try bint1.plus(bint2);

    print("a + b = {!s}\n", .{bint3.to_string()});

    var bint4 = try bint1.minus(bint2);

    print("a - b = {!s}\n", .{bint4.to_string()});
}
