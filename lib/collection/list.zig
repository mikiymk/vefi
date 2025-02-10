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

pub fn isList() void {
    @panic("not implemented");
}
