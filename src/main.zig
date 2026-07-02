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
    // .log_level = .info,
    .log_level = .debug,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var target = lib.algorithm.sort.LoggedSortTarget{};
    defer target.deinit(allocator);
    try target.resize(allocator, 1000);
    target.reset(.double_shuffle);

    try lib.algorithm.sort.merge_sort.timSort(allocator, &target);
}

const LoggedSortTarget = lib.sort.LoggedSortTarget;
