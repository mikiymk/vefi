//!

const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const Integer = @import("types/integer.zig");

pub const Tuple = @import("types/tuple.zig");
pub const Struct = @import("types/struct.zig");

pub const Array = @import("types/array.zig");
pub const Vector = @import("types/vector.zig");

pub const Pointer = @import("types/pointer.zig");
pub const Slice = @import("types/slice.zig");

pub const Optional = @import("types/optional.zig");
pub const error_union = @import("types/error-union.zig");

pub fn typeName(comptime T: type) []const u8 {
    return @typeName(T);
}
