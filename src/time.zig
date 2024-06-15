const std = @import("std");
const lib = @import("root.zig");

pub const date = struct {};
pub const time = struct {};

pub const timezone = struct {};

test {
    std.testing.refAllDecls(@This());
}
