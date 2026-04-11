//!

const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const integer = @import("types/integer.zig");

pub const tuple = @import("types/tuple.zig");
pub const zig_struct = @import("types/struct.zig");

pub const array = @import("types/array.zig");
pub const vector = @import("types/vector.zig");

pub const pointer = @import("types/pointer.zig");
pub const slice = @import("types/slice.zig");

pub const optional = @import("types/optional.zig");
pub const error_union = @import("types/error-union.zig");

pub fn typeName(comptime T: type) []const u8 {
    return @typeName(T);
}
