//!

const std = @import("std");
const builtin = @import("builtin");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const endian = builtin.cpu.arch.endian();
pub const Type = std.builtin.Type;
