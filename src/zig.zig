//! zigの基本の型と操作

const std = @import("std");
const lib = @import("root.zig");

pub const boolean = @import("zig/boolean.zig");
pub const integer = @import("zig/integer.zig");
pub const floating = @import("zig/floating.zig");

pub const optional = @import("zig/optional.zig");
pub const error_set = @import("zig/error_set.zig");
pub const error_union = @import("zig/error_union.zig");

pub const array = @import("zig/array.zig");
pub const vector = @import("zig/vector.zig");
pub const structure = @import("zig/structure.zig");
pub const enumeration = @import("zig/enumeration.zig");

pub const pointer = @import("zig/pointer.zig");
pub const slice = @import("zig/slice.zig");

pub const types = @import("zig/types.zig");

test {
    std.testing.refAllDecls(@This());
}
