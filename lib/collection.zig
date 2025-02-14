const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = std.mem.Allocator;

pub const array = @import("collection/array.zig");
pub const list = @import("collection/list.zig");
pub const stack = @import("collection/stack.zig");
pub const queue = @import("collection/queue.zig");
pub const tree = @import("collection/tree.zig");
pub const table = @import("collection/table.zig");

pub const doubly_list = struct {};
pub const circular_list = struct {};
pub const priority_queue = struct {};
pub const double_ended_queue = struct {};
pub const heap = struct {};
pub const tree_map = struct {};
pub const bidirectional_map = struct {};
pub const ordered_map = struct {};
pub const bit_array = struct {};

pub fn extendSize(allocator: Allocator, slice: anytype) Allocator.Error!@TypeOf(slice) {
    const initial_length = 8;
    const extend_factor = 2;

    const new_length: usize = if (slice.len == 0) initial_length else slice.len * extend_factor;

    return allocator.realloc(slice, new_length);
}
