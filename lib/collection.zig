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

//

pub const Array_Array = @import("array/DynamicArray.zig").DynamicArray;
pub const Array_CircularArray = @import("array/CircularArray.zig").CircularArray;
pub const List_List = @import("list/SinglyList.zig").SinglyList;
pub const List_SentinelList = @import("list/SentinelList.zig").SentinelList;
pub const List_CircularList = @import("list/CircularList.zig").CircularList;
pub const List_DoublyList = @import("list/DoublyList.zig").DoublyList;
pub const Stack_ArrayStack = @import("stack/ArrayStack.zig").ArrayStack;
pub const Stack_ListStack = @import("stack/ListStack.zig").ListStack;
pub const Queue_SinglyListQueue = @import("queue/SinglyListQueue.zig").SinglyListQueue;
pub const Queue_TwoStacksQueue = @import("queue/TwoStacksQueue.zig").TwoStacksQueue;
pub const Deque_DoublyListDeque = @import("queue/DoublyListDeque.zig").DoublyListDeque;
pub const Deque_CircularArrayDeque = @import("queue/CircularArrayDeque.zig").CircularArrayDeque;
pub const Tree_BinaryTree = @import("assoc_array/hash.zig").hash;
pub const Tree_BinarySearchTree = @import("assoc_array/hash.zig").hash;
pub const Tree_BalancedTree = @import("assoc_array/hash.zig").hash;
pub const AssocArray_List = @import("assoc_array/hash.zig").hash;
pub const AssocArray_Hash = @import("assoc_array/hash.zig").hash;
pub const AssocArray_Tree = @import("assoc_array/hash.zig").hash;

pub const SkipList = @import("list/SkipList.zig");
pub const BitArray = @import("array/BitArray.zig");
pub const BidiAssocArray = @import("array/BitArray.zig");

//

pub const Range = struct { usize, usize };

pub const array = @import("collection/array.zig");
pub const list = @import("collection/list.zig");
pub const stack = @import("collection/stack.zig");

pub const queue = @import("collection/queue.zig");
pub const tree = @import("collection/tree.zig");

pub const table = @import("collection/table.zig");

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
