const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const integer = struct {};
pub const big_integer = struct {};
pub const ratio = struct {};
pub const fixed_point = struct {};
pub const float_point = @import("math/float_point.zig");
pub const big_float_point = struct {};
pub const complex = struct {};

pub const Order = enum {
    equal,
    greater_than,
    less_than,
};
