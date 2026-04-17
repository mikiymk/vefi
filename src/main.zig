const std = @import("std");
const lib = @import("vefi");
const config = @import("config");

const BigInteger = @import("bigint.zig").BigInteger;
const fizz_buzz = @import("fizzbuzz.zig");
const prime = @import("prime.zig");

test {
    _ = @import("bigint.zig");
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    _ = allocator;

    // sort
    lib.sort;
    var array: [100]usize = undefined;
    var target = lib.sort.LoggedSortTarget{ .slice = &array };

    target.reset(.ascend);
    lib.sort.bubbleSort(target);
}
