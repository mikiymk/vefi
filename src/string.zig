const std = @import("std");
const lib = @import("./lib.zig");

pub const utf8_string = struct {};
pub const ascii_string = struct {};

test {
    std.testing.refAllDecls(@This());
}
