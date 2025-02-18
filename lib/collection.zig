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

pub const static_array = @import("./collection/array-static.zig");
pub const dynamic_array = @import("./collection/array-dynamic.zig");
pub const static_multi_dimensional_array = @import("./collection/array-static-multi-dimensional.zig");

pub fn isArray(T: type) bool {
    const match = lib.interface.match(T);

    return match.hasFunc("get") and
        match.hasFunc("set") and
        match.hasFunc("size");
}

pub fn isDynamicArray(T: type) bool {
    const match = lib.interface.match(T);

    return isArray(T) and
        match.hasFunc("pushFront") and
        match.hasFunc("pushBack") and
        match.hasFunc("popFront") and
        match.hasFunc("popBack");
}

test "array is array" {
    const expect = lib.assert.expect;

    try expect(isArray(static_array.StaticArray(u8, 5, .{})));
    try expect(isDynamicArray(dynamic_array.DynamicArray(u8, .{})));
}

pub const single_linear_list = @import("./collection/list-single-linear.zig");
pub const single_linear_sentinel_list = @import("./collection/list-single-linear-sentinel.zig");
pub const single_circular_list = @import("./collection/list-single-circular.zig");
pub const single_circular_sentinel_list = @import("./collection/list-single-circular-sentinel.zig");
pub const double_linear_list = @import("./collection/list-double-linear.zig");
pub const double_linear_sentinel_list = @import("./collection/list-double-linear-sentinel.zig");
pub const double_circular_list = struct {};
pub const double_circular_sentinel_list = struct {};

pub fn isList(T: type) bool {
    const match = lib.interface.match(T);

    return match.hasFunc("size") and
        match.hasFunc("clear") and
        match.hasFunc("get") and
        match.hasFunc("getFirst") and
        match.hasFunc("getLast") and
        match.hasFunc("add") and
        match.hasFunc("addFirst") and
        match.hasFunc("addLast") and
        match.hasFunc("remove") and
        match.hasFunc("removeFirst") and
        match.hasFunc("removeLast");
}

pub fn testList(List: type, list: *List, a: Allocator) !void {
    const expect = lib.assert.expect;

    // list == .{}
    try expect(list.size() == 0);
    try expect(list.getFirst() == null);
    try expect(list.getLast() == null);

    try list.addFirst(a, 4);
    try list.addFirst(a, 3);

    // list == .{3, 4}
    try expect(list.size() == 2);
    try expect(list.getFirst() == 3);
    try expect(list.getLast() == 4);
    try expect(list.get(0) == 3);
    try expect(list.get(1) == 4);

    try list.addLast(a, 7);
    try list.addLast(a, 8);

    // list == .{3, 4, 7, 8}
    try expect(list.size() == 4);
    try expect(list.get(0) == 3);
    try expect(list.get(1) == 4);
    try expect(list.get(2) == 7);
    try expect(list.get(3) == 8);

    try list.add(a, 2, 5);
    try list.add(a, 3, 6);

    // list == .{3, 4, 5, 6, 7, 8}
    try expect(list.size() == 6);
    try expect(list.getFirst() == 3);
    try expect(list.getLast() == 8);
    try expect(list.get(0) == 3);
    try expect(list.get(1) == 4);
    try expect(list.get(2) == 5);
    try expect(list.get(3) == 6);
    try expect(list.get(4) == 7);
    try expect(list.get(5) == 8);

    list.removeFirst(a);

    // list == .{4, 5, 6, 7, 8}
    try expect(list.size() == 5);
    try expect(list.get(0) == 4);
    try expect(list.get(1) == 5);
    try expect(list.get(2) == 6);
    try expect(list.get(3) == 7);
    try expect(list.get(4) == 8);

    list.removeLast(a);

    // list == .{4, 5, 6, 7}
    try expect(list.size() == 4);
    try expect(list.get(0) == 4);
    try expect(list.get(1) == 5);
    try expect(list.get(2) == 6);
    try expect(list.get(3) == 7);

    list.remove(a, 1);

    // list == .{4, 6, 7}
    try expect(list.size() == 3);
    try expect(list.get(0) == 4);
    try expect(list.get(1) == 6);
    try expect(list.get(2) == 7);

    list.clear(a);

    // list == .{}
    try expect(list.size() == 0);
    try expect(list.getFirst() == null);
    try expect(list.getLast() == null);

    try list.addFirst(a, 1);
    list.removeFirst(a);
    try expect(list.size() == 0);

    try list.addLast(a, 1);
    list.removeLast(a);
    try expect(list.size() == 0);

    try list.add(a, 0, 1);
    list.remove(a, 0);
    try expect(list.size() == 0);
}

test "list is list" {
    const expect = lib.assert.expect;

    try expect(isList(single_linear_list.SingleLinearList(u8)));
    try expect(isList(single_linear_sentinel_list.SingleLinearSentinelList(u8)));
    try expect(isList(single_circular_list.SingleCircularList(u8)));
    try expect(isList(single_circular_sentinel_list.SingleCircularSentinelList(u8)));
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
