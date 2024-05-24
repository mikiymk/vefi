//! zigの基本の型と操作

const std = @import("std");
const lib = @import("./lib.zig");

pub const boolean = @import("primitive/boolean.zig");
pub const integer = @import("primitive/integer.zig");
pub const floating = @import("primitive/floating.zig");

pub const optional = @import("primitive/optional.zig");
pub const error_set = @import("primitive/optional.zig");
pub const error_union = @import("primitive/optional.zig");

pub const array = @import("primitive/optional.zig");
pub const structure = @import("primitive/optional.zig");
pub const enumeration = @import("primitive/optional.zig");

pub const types = @import("primitive/optional.zig");

test {
    std.testing.refAllDecls(@This());
}
