//! # コレクション型
//!
//! ## 配列
//!
//! ### 配列の関数
//!
//! - get
//! - set
//! - size
//! - clear
//! - indexOf
//! - sort
//! - reverse
//!
//! ### 動的配列の関数
//!
//! - pushFront
//! - pushBack
//! - popFront
//! - popBack
//! - concat
//! - slice
//!
//! ### 配列の種類
//!
//! - 静的・動的
//! - 線形・環状
//!
//! ## リスト
//!
//! ### リストの関数
//!
//! - addFirst addLast add
//! - removeFirst removeLast remove
//! - getFirst getLast get
//! - size clear clone toSlice
//! - sort reverse
//! - toIterator
//!
//! ### リストの種類
//!
//! - 単方向・双方向
//! - 線形・循環
//! - 番兵ノード
//!
//! ### その他のリスト
//!
//! - アンロールドリスト
//! - スキップリスト
//! - XORリスト
//!
//! ## スタック
//!
//! ### スタックの関数
//!
//! - pop push
//! - peek size
//! - isEmpty clear
//! - iterator toSlice
//!
//! ### スタックの種類
//!
//! - 動的配列・線形リスト
//!
//! ## キュー
//!
//! ### キューの関数
//!
//! - enqueue dequeue
//! - peek size
//! - isEmpty clear
//!
//! ### キューの種類
//!
//! - 単方向キュー
//! - 両端キュー
//! - 優先度付きキュー
//!
//! ### キューの実装
//!
//! - 循環配列(固定長・可変長)
//! - リスト
//! - スタック
//!
//! ## ツリー
//!
//! ## 連想配列
//!
//! ### 連想配列の関数
//!
//! - add set get delete
//! - has
//! - size clear
//! - keys values entries
//!
//! ### 連想配列の種類
//!
//! ### 連想配列の実装
//!
//! - 配列・リスト
//! - ハッシュテーブル(チェイン法・オープンアドレス法)
//! - 木構造(二分木・平衡木)
//!

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

pub const StaticArray = @import("./collection/array-static.zig").StaticArray;
pub const DynamicArray = @import("./collection/array-dynamic.zig").DynamicArray;
pub const static_multi_dimensional_array = @import("./collection/array-static-multi-dimensional.zig");
pub const StringArray = @import("./collection/array-string.zig");
pub const bit_array = struct {};

pub fn isArray(T: type) bool {
    const match = lib.interface.match(T);

    return match.hasFn("get") and
        match.hasFn("set") and
        match.hasFn("size");
}

pub fn isDynamicArray(T: type) bool {
    const match = lib.interface.match(T);

    return isArray(T) and
        match.hasFn("pushFront") and
        match.hasFn("pushBack") and
        match.hasFn("popFront") and
        match.hasFn("popBack");
}

test "array is array" {
    const expect = lib.assert.expect;

    try expect(isArray(StaticArray(u8, 5)));
    try expect(isDynamicArray(DynamicArray(u8)));
    try expect(isDynamicArray(StringArray));
}

pub const generic_list = @import("./collection/generic-list.zig");
pub const generic_list_sentinel = @import("./collection/generic-list-sentinel.zig");

pub const SingleLinearList = @import("./collection/list-single-linear.zig").SingleLinearList;
pub const SingleLinearSentinelList = @import("./collection/list-single-linear-sentinel.zig").SingleLinearSentinelList;
pub const SingleCircularList = @import("./collection/list-single-circular.zig").SingleCircularList;
pub const SingleCircularSentinelList = @import("./collection/list-single-circular-sentinel.zig").SingleCircularSentinelList;
pub const DoubleLinearList = @import("./collection/list-double-linear.zig").DoubleLinearList;
pub const DoubleLinearSentinelList = @import("./collection/list-double-linear-sentinel.zig").DoubleLinearSentinelList;
pub const DoubleCircularList = @import("./collection/list-double-circular.zig").DoubleCircularList;
pub const DoubleCircularSentinelList = @import("./collection/list-double-circular-sentinel.zig").DoubleCircularSentinelList;

pub const test_list = @import("./collection/test-list.zig");

pub fn isList(T: type) bool {
    const match = lib.interface.match(T);

    return match.hasFn("size") and
        match.hasFn("clear") and
        match.hasFn("get") and
        match.hasFn("getFirst") and
        match.hasFn("getLast") and
        match.hasFn("add") and
        match.hasFn("addFirst") and
        match.hasFn("addLast") and
        match.hasFn("remove") and
        match.hasFn("removeFirst") and
        match.hasFn("removeLast");
}

pub fn isDoubleList(T: type) bool {
    const match = lib.interface.match(T);

    return isList(T) and
        match.hasFn("getFromLast");
}

test "list is list" {
    const expect = lib.assert.expect;

    try expect(isList(SingleLinearList(u8)));
    try expect(isList(SingleLinearSentinelList(u8)));
    try expect(isList(SingleCircularList(u8)));
    try expect(isList(SingleCircularSentinelList(u8)));
    try expect(isDoubleList(DoubleLinearList(u8)));
    try expect(isDoubleList(DoubleLinearSentinelList(u8)));
    try expect(isDoubleList(DoubleCircularList(u8)));
    try expect(isDoubleList(DoubleCircularSentinelList(u8)));
}

pub const stack = @import("collection/stack.zig");
pub const array_stack = @import("./collection/stack-array.zig");

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

pub fn extendSize(allocator: Allocator, slice: anytype) Allocator.Error!@TypeOf(slice) {
    const initial_length = 8;
    const extend_factor = 2;

    const new_length: usize = if (slice.len == 0) initial_length else slice.len * extend_factor;

    return allocator.realloc(slice, new_length);
}
