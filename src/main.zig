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

    // try lib.sort.sortLogging(allocator);
    try lib.sort.testSorts(allocator);
}

const LoggedSortTarget = lib.sort.LoggedSortTarget;
