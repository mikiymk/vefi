const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../../root.zig");
const LoggedSortTarget = lib.algorithm.sort.LoggedSortTarget;

test {
    std.testing.refAllDecls(@This());
}

fn isSorted(target: *LoggedSortTarget) bool {
    if (target.length() < 2) return true;
    for (1..target.length()) |i| {
        if (target.lessThanII(i, i - 1)) return false;
    }
    return true;
}

/// ボゴソート。
/// シャッフル→確認を繰り返す。
pub fn bogoSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    while (true) {
        lib.algorithm.shuffle.shuffle(target, lib.algorithm.random.random());
        if (isSorted(target)) break;
    }
}

/// ボゾソート。
/// 要素の交換→確認を繰り返す。
pub fn bozoSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    while (true) {
        const i = lib.algorithm.random.random().intRangeLessThan(usize, 0, target.length());
        const j = lib.algorithm.random.random().intRangeLessThan(usize, 0, target.length());
        target.swap(i, j);
        if (isSorted(target)) break;
    }
}

fn stoogeSortInternal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (target.lessThanII(end - 1, start)) {
        target.swap(end - 1, start);
    }

    if (2 < end - start) {
        const t = (end - start + 2) / 3;
        const t2 = ((end - start) * 2 + 2) / 3;
        stoogeSortInternal(target, start, start + t2);
        stoogeSortInternal(target, start + t, end);
        stoogeSortInternal(target, start, start + t2);
    }
}

/// ストゥージソート。
/// 2/3ずつ分割しながらソートする。
pub fn stoogeSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    stoogeSortInternal(target, 0, target.length());
}

fn slowSortInternal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end <= start + 1) return;
    const mid = (start + end - 1) / 2 + 1;
    slowSortInternal(target, start, mid);
    slowSortInternal(target, mid, end);
    if (target.lessThanII(end - 1, mid - 1)) {
        target.swap(end - 1, mid - 1);
    }
    slowSortInternal(target, start, end - 1);
}

/// スローソート。
/// 非効率に分割統治する。
pub fn slowSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    slowSortInternal(target, 0, target.length());
}
