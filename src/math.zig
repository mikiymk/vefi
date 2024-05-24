const std = @import("std");
const lib = @import("./lib.zig");

pub const integer = struct {};
pub const ratio = struct {};
pub const float = struct {};
pub const complex = struct {};

test {
    std.testing.refAllDecls(@This());
}
