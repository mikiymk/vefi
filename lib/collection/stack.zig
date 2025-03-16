const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;

test {
    std.testing.refAllDecls(@This());
}

pub const ArrayStack = @import("stack/array.zig").ArrayStack;
pub const ListStack = @import("stack/list.zig").ListStack;
