const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const integer = @import("math/integer.zig");
pub const big_integer = struct {};
pub const ratio = struct {};
pub const fixed_point = struct {};
pub const float_point = @import("math/float_point.zig");
pub const big_float_point = struct {};
pub const complex = struct {};

pub const Order = enum {
    /// left == right
    equal,
    /// left > right
    greater_than,
    /// left < right
    less_than,
};

pub fn absDiff(left: anytype, right: @TypeOf(left)) lib.types.Integer.Unsigned(@TypeOf(left)) {
    if (left > right) {
        return left - right;
    } else {
        return right - left;
    }
}
