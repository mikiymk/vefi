const std = @import("std");
const BigInteger = @import("bigint.zig").BigInteger;

test {
    _ = @import("bigint.zig");
}

pub fn main() !void {
    const print = std.debug.print;

    const stdin = std.io.getStdIn().reader();
    _ = stdin;

    var bint1 = try BigInteger.from_string(std.heap.page_allocator, "1234567890");
    var bint2 = try BigInteger.from_string(std.heap.page_allocator, "-9876543210");
    var bint3 = try BigInteger.from_string(std.heap.page_allocator, "9999999999999999999999");

    print("hello zig {!s} {!s} {!s}\n", .{ bint1.to_string(), bint2.to_string(), (try bint1.plus(bint3)).to_string() });

    bint1.deinit();
    bint2.deinit();
    bint3.deinit();
}
