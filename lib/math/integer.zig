//!

const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}
