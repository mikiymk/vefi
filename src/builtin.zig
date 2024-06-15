//!

const builtin = @import("builtin");

pub const endian = builtin.cpu.arch.endian();
