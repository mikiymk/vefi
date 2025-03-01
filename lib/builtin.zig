//!

const std = @import("std");
const builtin = @import("builtin");
const lib = @import("root.zig");

pub const endian = builtin.cpu.arch.endian();
pub const Type = std.builtin.Type;
