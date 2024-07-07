const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;

pub const dynamic_array = @import("collection/dynamic_array.zig");

pub const list = @import("collection/list.zig");
pub const doubly_list = struct {};
pub const circular_list = struct {};

pub const stack = @import("collection/stack.zig");
pub const queue = @import("collection/queue.zig");
pub const priority_queue = struct {};
pub const double_ended_queue = struct {};

pub const tree = struct {};
pub const avl_tree = @import("collection/avl_tree.zig");
pub const heap = struct {};

pub const hash_table = @import("collection/hash_table.zig");
pub const tree_map = struct {};
pub const bidirectional_map = struct {};
pub const ordered_map = struct {};

pub const bit_array = struct {};

pub fn extendSize(allocator: Allocator, array: anytype) Allocator.Error!@TypeOf(array) {
    const initial_length = 8;
    const extend_factor = 2;

    const new_length: usize = if (array.len == 0) initial_length else array.len * extend_factor;

    return allocator.realloc(array, new_length);
}
