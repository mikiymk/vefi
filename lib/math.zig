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

pub fn compare(left: anytype, right: @TypeOf(left)) Order {
    if (left > right) return .greater_than;
    if (left < right) return .less_than;
    return .equal;
}

pub fn absDiff(left: anytype, right: @TypeOf(left)) lib.types.Integer.Unsigned(@TypeOf(left)) {
    if (left > right) {
        return left - right;
    } else {
        return right - left;
    }
}

pub fn sin() void {}
pub fn cos() void {}
pub fn tan() void {}
pub fn asin() void {}
pub fn acos() void {}
pub fn atan() void {}
pub fn atan2() void {}

pub fn sinh() void {}
pub fn cosh() void {}
pub fn tanh() void {}
pub fn asinh() void {}
pub fn acosh() void {}
pub fn atanh() void {}
