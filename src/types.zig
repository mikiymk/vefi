//!

const std = @import("std");
const lib = @import("root.zig");

pub const Array = @import("types/array.zig");
pub const Slice = @import("types/slice.zig");

pub fn typeName(comptime T: type) []const u8 {
    return @typeName(T);
}

test {
    std.testing.refAllDecls(@This());
}
