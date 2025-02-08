const std = @import("std");
const lib = @import("ziglib");
const config = @import("config");

const BigInteger = @import("bigint.zig").BigInteger;
const fizz_buzz = @import("./fizzbuzz.zig");

test {
    _ = @import("bigint.zig");
}

const Array = lib.collection.array.static_array.StaticArray(u8, 5, .{});

pub fn main() !void {
    const print = std.debug.print;
    const allocator = std.heap.page_allocator;

    const array = Array.init(0);
    print("{any}", .{array});

    if (config.is_enabled) {
        print("enabled\n", .{});
    } else {
        @panic("disabled! add -Dis_enabled=true flag on compile!");
    }

    try fizz_buzz.fizz(100, std.io.getStdOut().writer(), .{});

    const stdin = std.io.getStdIn().reader();

    print("input your number... ", .{});
    const buf = try stdin.readUntilDelimiterAlloc(allocator, '\n', 280);
    const line_buf = std.mem.trimRight(u8, buf, "\r");

    print("hello zig!\n", .{});

    var bint1 = try BigInteger.fromString(allocator, line_buf);

    print("a: your input = {!s}\n", .{bint1.toString()});

    var bint2 = try BigInteger.fromInt(u32, allocator, 1234567890);

    print("b: my number = {!s}\n", .{bint2.toString()});

    var bint3 = try bint1.plus(bint2);

    print("a + b = {!s}\n", .{bint3.toString()});

    var bint4 = try bint1.minus(bint2);

    print("a - b = {!s}\n", .{bint4.toString()});
}
