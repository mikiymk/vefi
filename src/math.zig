const std = @import("std");
const lib = @import("root.zig");

pub const integer = struct {};
pub const big_integer = struct {};
pub const ratio = struct {};
pub const fixed_point = struct {};
pub const float_point = struct {};
pub const big_float_point = struct {};
pub const complex = struct {};

test {
    std.testing.refAllDecls(@This());
}
