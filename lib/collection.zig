const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = std.mem.Allocator;

pub const Range = struct {
    begin: usize,
    end: usize,
};

// 配列の関数
// get set
// size clear
// indexOf
// sort reverse

// 動的配列
// pushFront pushBack popFront popBack
// concat slice

// 配列の種類
// 静的・動的
// 線形・環状

pub const static_array = @import("./collection/array-static.zig");
pub const dynamic_array = @import("./collection/array-dynamic.zig");
pub const static_multi_dimensional_array = @import("./collection/array-static-multi-dimensional.zig");

pub fn expectArray(T: type) !void {
    const interface = lib.interface.match(T);

    if (!interface.hasFunc("get")) return error.NotImplemented;
    if (!interface.hasFunc("set")) return error.NotImplemented;
    if (!interface.hasFunc("size")) return error.NotImplemented;
}

pub fn expectDynamicArray(T: type) !void {
    const interface = lib.interface.match(T);

    try expectArray(T);
    if (!interface.hasFunc("get")) return error.NotImplemented;
    if (!interface.hasFunc("set")) return error.NotImplemented;
    if (!interface.hasFunc("size")) return error.NotImplemented;
}

test "array is array" {
    try expectArray(static_array.StaticArray(u8, 5, .{}));
    try expectArray(dynamic_array.DynamicArray(u8, .{}));
    try expectDynamicArray(dynamic_array.DynamicArray(u8, .{}));
}

// リストの関数
// addFirst addLast add
// removeFirst removeLast remove
// getFirst getLast get
// size clear clone toSlice
// sort reverse
// toIterator

// リストの種類
// 単方向・双方向
// 線形・循環
// 番兵ノード

// アンロールドリスト
// スキップリスト
// XORリスト

pub const single_linear_list = @import("./collection/list-single-linear.zig");
pub const single_linear_sentinel_list = @import("./collection/list-single-linear-sentinel.zig");
pub const single_circular_list = @import("./collection/list-single-circular.zig");
pub const single_circular_sentinel_list = @import("./collection/list-single-circular-sentinel.zig");
pub const double_linear_list = struct {};
pub const double_linear_sentinel_list = struct {};
pub const double_circular_list = struct {};
pub const double_circular_sentinel_list = struct {};

pub fn expectList(T: type) !void {
    const interface = lib.interface.match(T);

    if (!interface.hasFunc("size")) return error.NotImplemented;
    if (!interface.hasFunc("clear")) return error.NotImplemented;
    if (!interface.hasFunc("get")) return error.NotImplemented;
    if (!interface.hasFunc("getFirst")) return error.NotImplemented;
    if (!interface.hasFunc("getLast")) return error.NotImplemented;
    if (!interface.hasFunc("add")) return error.NotImplemented;
    if (!interface.hasFunc("addFirst")) return error.NotImplemented;
    if (!interface.hasFunc("addLast")) return error.NotImplemented;
    if (!interface.hasFunc("remove")) return error.NotImplemented;
    if (!interface.hasFunc("removeFirst")) return error.NotImplemented;
    if (!interface.hasFunc("removeLast")) return error.NotImplemented;
}

test "list is list" {
    try expectList(single_linear_list.SingleLinearList(u8));
    try expectList(single_linear_sentinel_list.SingleLinearSentinelList(u8));
    try expectList(single_circular_list.SingleCircularList(u8));
    try expectList(single_circular_sentinel_list.SingleCircularSentinelList(u8));
}

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
