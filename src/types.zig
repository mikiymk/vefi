//!

const std = @import("std");
const lib = @import("root.zig");

pub const Integer = @import("types/integer.zig");

pub const Tuple = @import("types/tuple.zig");
pub const Struct = @import("types/struct.zig");

pub const Array = @import("types/array.zig");
pub const Slice = @import("types/slice.zig");

pub fn typeName(comptime T: type) []const u8 {
    return @typeName(T);
}

test {
    std.testing.refAllDecls(@This());
}
