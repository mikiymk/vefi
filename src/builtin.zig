//!

const std = @import("std");
const builtin = @import("builtin");

pub const endian = builtin.cpu.arch.endian();
pub const Type = std.builtin.Type;
