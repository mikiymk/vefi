const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../../root.zig");
const LoggedSortTarget = lib.algorithm.sort.LoggedSortTarget;

test {
    std.testing.refAllDecls(@This());
}

/// クイックソートで小さい値を前、大きい値を後ろに移動し、ピボット位置を返す。
/// Lomuto法。
fn quickSort1Partition(target: *LoggedSortTarget, start: usize, end: usize) usize {
    // 最後の要素をピボットにする
    const pivot = target.get(end - 1);

    var i = start;
    for (start..end - 1) |j| {
        if (target.lessThanIV(j, pivot)) {
            target.swap(i, j);
            i += 1;
        }
    }
    target.swap(i, end - 1);
    return i;
}

/// 分割されたロムート法クイックソート。
/// startは含む、endは含まない。
fn quickSort1Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end <= start + 1) return;
    const partition = quickSort1Partition(target, start, end);
    quickSort1Internal(target, start, partition);
    quickSort1Internal(target, partition + 1, end);
}

/// クイックソート。
/// ある値より大きい値と小さい値に分類するのを繰り返す。
/// ロムート法。
pub fn quickSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    quickSort1Internal(target, 0, target.length());
}

/// クイックソートで小さい値を前、大きい値を後ろに移動し、ピボット位置を返す。
/// Hoare法。
fn quickSort2Partition(target: *LoggedSortTarget, start: usize, end: usize) usize {
    var lo = start;
    var hi = end - 1;
    const pivot = target.get((start + end - 1) / 2);
    while (true) {
        while (target.lessThanIV(lo, pivot)) lo += 1;
        while (target.lessThanVI(pivot, hi)) hi -= 1;
        if (lo >= hi) return hi + 1;

        target.swap(lo, hi);
        lo += 1;
        hi -= 1;
    }
}

/// 分割されたホーア法クイックソート。
/// startは含む、endは含まない。
fn quickSort2Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    // 要素数が0または1の場合
    if (end <= start + 1) return;

    const partition = quickSort2Partition(target, start, end);
    quickSort2Internal(target, start, partition);
    quickSort2Internal(target, partition, end);
}

/// クイックソート。
/// ある値より大きい値と小さい値に分類するのを繰り返す。
/// ホーア法。
pub fn quickSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    quickSort2Internal(target, 0, target.length());
}

/// クイックソートで小さい値を前、等しい値を真ん中、大きい値を後ろに移動し、ピボット位置を返す。
/// 三叉パーティション。
fn quickSort3Partition(target: *LoggedSortTarget, start: usize, end: usize) struct { usize, usize } {
    var lo = start;
    var mi = start;
    var hi = end - 1;
    const pivot = target.get((start + end - 1) / 2);

    debug("ピボット {}", .{pivot.v});
    debug("{f} low:{} mid:{} high:{}", .{ target, lo, mi, hi });
    while (mi <= hi) {
        if (target.lessThanIV(mi, pivot)) {
            target.swap(lo, mi);
            lo += 1;
            mi += 1;
        } else if (target.lessThanVI(pivot, mi)) {
            target.swap(mi, hi);
            hi -= 1;
        } else {
            mi += 1;
        }
        debug("{f} low:{} mid:{} high:{}", .{ target, lo, mi, hi });
    }
    return .{ lo, hi + 1 };
}

/// 分割された三叉クイックソート。
/// startは含む、endは含まない。
fn quickSort3Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    debug("{f}", .{target});
    debug("範囲 {} - {} 要素数 {}", .{ start, end, end - start });
    // 要素数が0または1の場合
    if (end <= start + 1) return;

    const partition1, const partition2 = quickSort3Partition(target, start, end);
    debug("パーティション {}, {}", .{ partition1, partition2 });
    quickSort3Internal(target, start, partition1);
    quickSort3Internal(target, partition2, end);
}

/// クイックソート。
/// ある値より大きい値と小さい値に分類するのを繰り返す。
/// 三叉パーティション
pub fn quickSort3(_: Allocator, target: *LoggedSortTarget) error{}!void {
    quickSort3Internal(target, 0, target.length());
}

/// イントロソートの挿入ソート部分。
/// start .. end を挿入ソートで整列する。
fn introSortInsertion(target: *LoggedSortTarget, start: usize, end: usize) void {
    for (start..end) |i| {
        var j = i;
        while (start < j and target.lessThanII(j, j - 1)) : (j -= 1) {
            target.swap(j, j - 1);
        }
    }
}

/// indexの左の子を見つける。
fn introSortLeftChild(offset: usize, index: usize) usize {
    return offset + (index - offset) * 2 + 1;
}

/// indexの右の子を見つける。
fn introSortRightChild(offset: usize, index: usize) usize {
    return offset + (index - offset) * 2 + 2;
}

/// indexの親を見つける。
fn introSortParent(offset: usize, index: usize) usize {
    return offset + (index - offset - 1) / 2;
}

fn introSortLeafSearch(target: *LoggedSortTarget, offset: usize, index: usize, heap_size: usize) usize {
    var j = index;
    while (introSortRightChild(offset, j) < heap_size) {
        const left = introSortLeftChild(offset, j);
        const right = introSortRightChild(offset, j);
        j = if (target.lessThanII(left, right)) right else left;
    }
    if (introSortLeftChild(offset, j) < heap_size) {
        j = introSortLeftChild(offset, j);
    }
    return j;
}

/// ボトムアップでシフトダウンする。
fn introSortShiftDown(target: *LoggedSortTarget, offset: usize, index: usize, heap_size: usize) void {
    var j = introSortLeafSearch(target, offset, index, heap_size);
    while (target.lessThanII(j, index)) {
        j = introSortParent(offset, j);
    }
    while (index < j) {
        target.swap(index, j);
        j = introSortParent(offset, j);
    }
}

/// イントロソートのヒープソート部分。
/// [start, end) をヒープソートで整列する。
fn introSortHeap(target: *LoggedSortTarget, start: usize, end: usize) void {
    const length = end - start;
    if (length < 2) return;

    {
        var heap_start = start + length / 2;
        while (start < heap_start) {
            heap_start -= 1;
            introSortShiftDown(target, start, heap_start, end);
        }
    }

    {
        var heap_end = end - 1;
        while (start < heap_end) : (heap_end -= 1) {
            target.swap(start, heap_end);
            introSortShiftDown(target, start, start, heap_end);
        }
    }
}

/// イントロソートのクイックソート部分。
fn introSortInternal(target: *LoggedSortTarget, start: usize, end: usize, max_depth: usize) void {
    if (end <= start + 16) {
        // 要素数が16以下の場合
        introSortInsertion(target, start, end);
    } else if (max_depth == 0) {
        // 深さが log2 * 2 に到達した場合
        introSortHeap(target, start, end);
    } else {
        const partition = quickSort2Partition(target, start, end);
        introSortInternal(target, start, partition, max_depth - 1);
        introSortInternal(target, partition, end, max_depth - 1);
    }
}

/// イントロソート。
/// クイックソートの弱点をヒープソートと挿入ソートで補う。
pub fn introSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    const max_depth: usize = std.math.log2_int(usize, target.length()) * 2;
    introSortInternal(target, 0, target.length(), max_depth);
}
