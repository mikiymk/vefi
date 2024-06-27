const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const date = struct {};
pub const time = struct {};

pub const timezone = struct {};
