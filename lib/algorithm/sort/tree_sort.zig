const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../../root.zig");
const LoggedSortTarget = lib.algorithm.sort.LoggedSortTarget;

test {
    std.testing.refAllDecls(@This());
}

const TreeSortTree = struct {
    node: LoggedSortTarget.Type,
    left: ?*TreeSortTree = null,
    right: ?*TreeSortTree = null,
};

/// ツリーに挿入する。
fn treeSortInsert(target: *LoggedSortTarget, search_tree: *?*TreeSortTree, new_node: *TreeSortTree) !void {
    if (search_tree.*) |tree| {
        if (target.lessThanVV(new_node.node, tree.node)) {
            try treeSortInsert(target, &tree.left, new_node);
        } else {
            try treeSortInsert(target, &tree.right, new_node);
        }
    } else {
        search_tree.* = new_node;
    }
}

/// ツリーの要素を配置しなおす。
fn treeSortInOrder(allocator: Allocator, target: *LoggedSortTarget, search_tree: *?*TreeSortTree, n: *usize) void {
    if (search_tree.*) |tree| {
        treeSortInOrder(allocator, target, &tree.left, n);
        target.set(n.*, tree.node);
        n.* += 1;
        treeSortInOrder(allocator, target, &tree.right, n);
        allocator.destroy(tree);
        search_tree.* = null;
    } else {
        return;
    }
}

/// ツリーソート。
/// 二分探索木を使用してソートする。
pub fn treeSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    var search_tree: ?*TreeSortTree = null;

    for (0..target.length()) |i| {
        const tree = try allocator.create(TreeSortTree);
        tree.* = TreeSortTree{ .node = target.get(i) };
        try treeSortInsert(target, &search_tree, tree);
        debug("{any}", .{search_tree});
    }

    var n: usize = 0;
    treeSortInOrder(allocator, target, &search_tree, &n);
}

/// indexの左の子を見つける。
fn heapSortLeftChild(index: usize) usize {
    return index * 2 + 1;
}

/// indexの右の子を見つける。
fn heapSortRightChild(index: usize) usize {
    return index * 2 + 2;
}

/// indexの親を見つける。
fn heapSortParent(index: usize) usize {
    return (index - 1) / 2;
}

/// S[0]からS[i-1]のヒープにS[i]を追加してS[0]からS[i]のヒープを再構成する。
fn heapSort1ShiftUp(target: *LoggedSortTarget, index: usize) void {
    var node = index;
    while (node > 0) {
        const parent = heapSortParent(node);
        if (target.lessThanII(parent, node)) { // 親と比較して逆順なら入れ替える。
            target.swap(parent, node);
            node = parent;
        } else { // 正順なら終了。
            break;
        }
    }
}

/// ルートをiとするヒープを作成する。
/// Left(i)とRight(i)はヒープ。
fn heapSort1ShiftDown(target: *LoggedSortTarget, index: usize, heap_size: usize) void {
    var current_index = index;
    while (true) {
        var max = current_index;
        const left_child = heapSortLeftChild(current_index);
        const right_child = heapSortRightChild(current_index);

        if (left_child < heap_size and target.lessThanII(max, left_child)) {
            max = left_child;
        }
        if (right_child < heap_size and target.lessThanII(max, right_child)) {
            max = right_child;
        }

        if (max == current_index) return;
        target.swap(max, current_index);
        current_index = max;
    }
}

/// ヒープソート。
/// データ構造のヒープを使用する。
/// Williamのアルゴリズム。
pub fn heapSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var i: usize = 1;
    while (i < target.length()) : (i += 1) {
        heapSort1ShiftUp(target, i);
    }

    i -= 1;
    while (i > 0) : (i -= 1) {
        target.swap(0, i);
        heapSort1ShiftDown(target, 0, i);
    }
}

/// ヒープソート。
/// データ構造のヒープを使用する。
/// Floydのアルゴリズム。
pub fn heapSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;

    {
        var start = target.length() / 2;
        while (0 < start) {
            start -= 1;
            heapSort1ShiftDown(target, start, target.length());
        }
    }

    {
        var end = target.length() - 1;
        while (0 < end) : (end -= 1) {
            target.swap(0, end);
            heapSort1ShiftDown(target, 0, end);
        }
    }
}

fn heapSort3LeafSearch(target: *LoggedSortTarget, index: usize, heap_size: usize) usize {
    var j = index;
    while (heapSortRightChild(j) < heap_size) {
        const left = heapSortLeftChild(j);
        const right = heapSortRightChild(j);
        j = if (target.lessThanII(left, right)) right else left;
    }
    if (heapSortLeftChild(j) < heap_size) {
        j = heapSortLeftChild(j);
    }
    return j;
}

/// ボトムアップでシフトダウンする。
fn heapSort3ShiftDown(target: *LoggedSortTarget, index: usize, heap_size: usize) void {
    var j = heapSort3LeafSearch(target, index, heap_size);
    while (target.lessThanII(j, index)) {
        j = heapSortParent(j);
    }
    while (index < j) {
        target.swap(index, j);
        j = heapSortParent(j);
    }
}

/// ヒープソート。
/// データ構造のヒープを使用する。
/// Floydのアルゴリズム。
pub fn heapSort3(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;

    {
        var start = target.length() / 2;
        while (0 < start) {
            start -= 1;
            heapSort3ShiftDown(target, start, target.length());
        }
    }

    {
        var end = target.length() - 1;
        while (0 < end) : (end -= 1) {
            target.swap(0, end);
            heapSort3ShiftDown(target, 0, end);
        }
    }
}

// 参考ページ https://www.keithschwarz.com/smoothsort/

var smooth_leonardo_array: [92]usize = undefined; // max(usize) < L[92] なのでそれ以上の要素数は不要。
/// 指定した数以下のレオナルド数をすべて求めて配列にして返す。
/// L[0] = 1, L[1] = 1, L[n] = L[n-1] + L[n-2] + 1;
fn smoothSortLeonardo(num: usize) []usize {
    if (num < 1) return &.{};

    smooth_leonardo_array[0] = 1;
    smooth_leonardo_array[1] = 1;

    var n: usize = 2;
    while (true) {
        const ln = smooth_leonardo_array[n - 2] + smooth_leonardo_array[n - 1] + 1;
        if (num < ln) break;
        smooth_leonardo_array[n] = ln;
        n += 1;
    }

    return smooth_leonardo_array[0..n];
}

/// 1つの木 S[start] から S[end-1] の範囲を再構築する。
fn smoothSort1InsertTree(target: *LoggedSortTarget, la: []const usize, start: usize, tree_size: usize) void {
    if (tree_size < 2) return;

    const parent_index = start + la[tree_size] - 1;
    const left_child_index = start + la[tree_size - 1] - 1;
    const right_child_index = start + la[tree_size] - 2;

    var swap_child_index = left_child_index;
    var swap_child_tree_size = tree_size - 1;
    if (target.lessThanII(left_child_index, right_child_index)) {
        // 左の子 < 右の子なら右の子と交換する。
        swap_child_index = right_child_index;
        swap_child_tree_size = tree_size - 2;
    }

    if (target.lessThanII(parent_index, swap_child_index)) {
        // 親 < 子なら交換する。
        target.swap(parent_index, swap_child_index);
        // 子をルートにして再帰処理
        smoothSort1InsertTree(target, la, swap_child_index + 1 - la[swap_child_tree_size], swap_child_tree_size);
    }
}

/// 森を1つ成長させる。
fn smoothSort1GrowForest(allocator: Allocator, tree_sizes: *std.ArrayList(usize)) Allocator.Error!void {
    if (2 <= tree_sizes.items.len and tree_sizes.items[tree_sizes.items.len - 1] + 1 == tree_sizes.items[tree_sizes.items.len - 2]) {
        // もし最後2つの木が L[n-1] と L[n-2] なら、合体して L[n] にする。
        _ = tree_sizes.pop();
        tree_sizes.items[tree_sizes.items.len - 1] += 1;
    } else if (1 <= tree_sizes.items.len and tree_sizes.items[tree_sizes.items.len - 1] == 1) {
        // もし最後の木が L[1] なら、 L[0] として追加する。
        try tree_sizes.append(allocator, 0);
    } else {
        // それ以外の場合は L[1] として追加する。
        try tree_sizes.append(allocator, 1);
    }
}

/// 前の木と現在の木を比べてルート同士を交換するか判定する。
fn smoothSort1ShouldSwapRoot(target: *LoggedSortTarget, la: []const usize, current_root: usize, prev_root: usize, tree_size: usize) bool {
    const should_swap = target.lessThanII(current_root, prev_root);
    if (1 < tree_size) {
        // 現在の木に子があるなら、前のルート < 子の場合に交換しない。
        const current_left_child = current_root - la[tree_size - 2] - 1;
        const current_right_child = current_root - 1;
        return should_swap and
            target.lessThanII(current_left_child, prev_root) and
            target.lessThanII(current_right_child, prev_root);
    }

    return should_swap;
}

/// 森を再構築する。
fn smoothSort1Rebalance(target: *LoggedSortTarget, la: []const usize, tree_sizes: std.ArrayList(usize), heap_size: usize) void {
    var current_root = heap_size - 1;
    var tree_index = tree_sizes.items.len - 1;

    while (0 < tree_index) {
        const tree_size = tree_sizes.items[tree_index];
        const prev_root = current_root - la[tree_size];

        if (!smoothSort1ShouldSwapRoot(target, la, current_root, prev_root, tree_size)) {
            // 交換しないなら終了。
            break;
        }

        // 前の木のルートが大きいなら、交換する。
        target.swap(prev_root, current_root);
        current_root = prev_root;
        tree_index -= 1;
    }

    // 一番前に来た場合は一番前の木を再構築する。
    smoothSort1InsertTree(target, la, current_root + 1 - la[tree_sizes.items[tree_index]], tree_sizes.items[tree_index]);
}

/// 複数の木のリスト S[0] から S[end] までの範囲を再構築する。
fn smoothSort1InsertForest(allocator: Allocator, target: *LoggedSortTarget, la: []const usize, tree_sizes: *std.ArrayList(usize), heap_size: usize) Allocator.Error!void {
    try smoothSort1GrowForest(allocator, tree_sizes);
    smoothSort1Rebalance(target, la, tree_sizes.*, heap_size);
}

/// 最大の要素を取り出し、森を再構築する。
fn smoothSort1ShrinkForest(allocator: Allocator, target: *LoggedSortTarget, la: []const usize, tree_sizes: *std.ArrayList(usize), heap_size: usize) Allocator.Error!void {
    const last = tree_sizes.pop() orelse unreachable;
    // L[0] または L[1] の場合はそのまま削除する。
    if (1 < last) {
        // それ以外の場合は L[n] を L[n-1] と L[n-2] に分割して再構築する。
        try tree_sizes.append(allocator, last - 1);
        smoothSort1Rebalance(target, la, tree_sizes.*, heap_size - la[last - 2] - 1);
        try tree_sizes.append(allocator, last - 2);
        smoothSort1Rebalance(target, la, tree_sizes.*, heap_size - 1);
    }
}

/// スムーズソート。
/// ツリーの長さ列にスタックを使用する。
pub fn smoothSort1(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    const la = smoothSortLeonardo(target.length());

    var tree_sizes = std.ArrayList(usize).empty;
    defer tree_sizes.deinit(allocator);

    for (1..target.length() + 1) |heap_size| {
        try smoothSort1InsertForest(allocator, target, la, &tree_sizes, heap_size);
    }

    {
        var heap_size = target.length();
        while (heap_size > 1) : (heap_size -= 1) {
            try smoothSort1ShrinkForest(allocator, target, la, &tree_sizes, heap_size);
        }
    }
}

/// 1つの木 S[start] から S[end-1] の範囲を再構築する。
fn smoothSort2InsertTree(target: *LoggedSortTarget, la: []const usize, start: usize, tree_size: usize) void {
    if (tree_size < 2) return;

    const parent_index = start + la[tree_size] - 1;
    const left_child_index = start + la[tree_size - 1] - 1;
    const right_child_index = start + la[tree_size] - 2;

    var swap_child_index = left_child_index;
    var swap_child_tree_size = tree_size - 1;
    if (target.lessThanII(left_child_index, right_child_index)) {
        // 左の子 < 右の子なら右の子と交換する。
        swap_child_index = right_child_index;
        swap_child_tree_size = tree_size - 2;
    }

    if (target.lessThanII(parent_index, swap_child_index)) {
        // 親 < 子なら交換する。
        target.swap(parent_index, swap_child_index);
        // 子をルートにして再帰処理
        smoothSort2InsertTree(target, la, swap_child_index + 1 - la[swap_child_tree_size], swap_child_tree_size);
    }
}

/// 森を1つ成長させる。
fn smoothSort2GrowForest(tree_sizes_vec: *usize, tree_sizes_zero_pointer: *usize) void {
    if (tree_sizes_vec.* & 3 == 0b11) {
        // もし最後2つの木が L[n-1] と L[n-2] なら、合体して L[n] にする。
        // (m011, n) -> (m1, n+2)
        tree_sizes_vec.* = (tree_sizes_vec.* >> 2) + 1;
        tree_sizes_zero_pointer.* += 2;
    } else if (tree_sizes_vec.* & 1 == 0b1 and tree_sizes_zero_pointer.* == 1) {
        // もし最後の木が L[1] なら、 L[0] として追加する。
        // (m01, 1) -> (m011, 0)
        tree_sizes_vec.* = (tree_sizes_vec.* << 1) + 1;
        tree_sizes_zero_pointer.* = 0;
    } else {
        // それ以外の場合は L[1] として追加する。
        // (m1, n) -> (m100...01, 1)
        if (tree_sizes_vec.* != 0) {
            tree_sizes_vec.* = (tree_sizes_vec.* << @intCast(tree_sizes_zero_pointer.* - 1)) + 1;
        } else {
            tree_sizes_vec.* = 1;
        }
        tree_sizes_zero_pointer.* = 1;
    }
}

/// 森を再構築する。
fn smoothSort2Rebalance(target: *LoggedSortTarget, la: []const usize, tree_sizes_vec: *const usize, tree_sizes_zero_pointer: *const usize, heap_size: usize) void {
    var current_root = heap_size - 1;
    var vec = tree_sizes_vec.*;
    var tree_size = tree_sizes_zero_pointer.*;

    while (1 < vec) {
        if (vec & 1 == 0) {
            // この大きさの木が存在しない場合
            vec >>= 1;
            tree_size += 1;
            continue;
        }

        const prev_root = current_root - la[tree_size];

        if (!smoothSort1ShouldSwapRoot(target, la, current_root, prev_root, tree_size)) {
            // 交換しないなら終了。
            break;
        }

        // 前の木のルートが大きいなら、交換する。
        target.swap(prev_root, current_root);
        current_root = prev_root;
        vec >>= 1;
        tree_size += 1;
    }

    // 一番前に来た場合は一番前の木を再構築する。
    smoothSort2InsertTree(target, la, current_root + 1 - la[tree_size], tree_size);
}

/// 複数の木のリスト S[0] から S[end] までの範囲を再構築する。
fn smoothSort2InsertForest(target: *LoggedSortTarget, la: []const usize, tree_sizes_vec: *usize, tree_sizes_zero_pointer: *usize, heap_size: usize) void {
    smoothSort2GrowForest(tree_sizes_vec, tree_sizes_zero_pointer);
    smoothSort2Rebalance(target, la, tree_sizes_vec, tree_sizes_zero_pointer, heap_size);
}

/// 最大の要素を取り出し、森を再構築する。
fn smoothSort2ShrinkForest(target: *LoggedSortTarget, la: []const usize, tree_sizes_vec: *usize, tree_sizes_zero_pointer: *usize, heap_size: usize) void {
    const last = tree_sizes_zero_pointer.*;
    if (2 <= last) {
        // それ以外の場合は L[n] を L[n-1] と L[n-2] に分割して再構築する。
        tree_sizes_vec.* = tree_sizes_vec.* - 1;
        tree_sizes_vec.* = (tree_sizes_vec.* << 1) + 1;
        tree_sizes_zero_pointer.* -= 1;
        smoothSort2Rebalance(target, la, tree_sizes_vec, tree_sizes_zero_pointer, heap_size - la[last - 2] - 1);
        tree_sizes_vec.* = (tree_sizes_vec.* << 1) + 1;
        tree_sizes_zero_pointer.* -= 1;
        smoothSort2Rebalance(target, la, tree_sizes_vec, tree_sizes_zero_pointer, heap_size - 1);
    } else if (last == 1) {
        // L[0] または L[1] の場合はそのまま削除する。
        tree_sizes_vec.* = tree_sizes_vec.* - 1;
        const ctz = @ctz(tree_sizes_vec.*);
        tree_sizes_vec.* = tree_sizes_vec.* >> @intCast(ctz);
        tree_sizes_zero_pointer.* = ctz + 1;
    } else {
        tree_sizes_vec.* = tree_sizes_vec.* >> 1;
        tree_sizes_zero_pointer.* = 1;
    }
}

/// スムーズソート。
/// ツリーの長さ列にビット列とシフト数を使用する。
pub fn smoothSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    const la = smoothSortLeonardo(target.length());

    var tree_sizes_vec: usize = 0;
    var tree_sizes_zero_pointer: usize = 0;

    for (1..target.length() + 1) |heap_size| {
        smoothSort2InsertForest(target, la, &tree_sizes_vec, &tree_sizes_zero_pointer, heap_size);
    }

    {
        var heap_size = target.length();
        while (heap_size > 1) : (heap_size -= 1) {
            smoothSort2ShrinkForest(target, la, &tree_sizes_vec, &tree_sizes_zero_pointer, heap_size);
        }
    }
}
