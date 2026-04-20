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

    // sort
    var array: [100]usize = undefined;
    var target = lib.sort.LoggedSortTarget{ .slice = &array };

    for (0..100) |_| {
        target.reset(.shuffle);
        std.debug.print("{any}\n", .{target.slice});
        try lib.sort.quickSort2(allocator, &target);
        std.debug.print("{any}\n", .{target.slice});
        if (!target.isSorted()) {
            std.debug.print("not sorted\n", .{});
            return;
        }
    }
}
