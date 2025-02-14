//!

const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const AllocatorError = lib.allocator.AllocatorError;

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

pub const single_linear_list = @import("./list_single_linear.zig");
pub const single_linear_sentinel_list = struct {};
pub const single_circular_list = struct {};
pub const single_circular_sentinel_list = struct {};
pub const double_linear_list = struct {};
pub const double_linear_sentinel_list = struct {};
pub const double_circular_list = struct {};
pub const double_circular_sentinel_list = struct {};

pub fn expectList(T: type) !void {
    const interface = lib.interface.match(T);

    if (!interface.hasFunc("size")) return error.NotImplemented;
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
}
