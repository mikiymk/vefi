const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../../root.zig");
const LoggedSortTarget = lib.algorithm.sort.LoggedSortTarget;

test {
    std.testing.refAllDecls(@This());
}

/// バブルソート。
/// すべての要素について、隣と比較して逆順なら入れ替える。
/// 要素数-1回繰り返す。
pub fn bubbleSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |_| {
        for (1..target.length()) |j| {
            if (target.lessThanII(j, j - 1)) target.swap(j, j - 1);
        }
    }
}

/// バブルソート。
/// ソート済みが確定しているところは比較を行わない。
pub fn bubbleSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        for (1..target.length() - i) |j| {
            if (target.lessThanII(j, j - 1)) target.swap(j, j - 1);
        }
    }
}

/// バブルソート。
/// 最後の入れ替え位置より後ろは比較しない。
pub fn bubbleSort3(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var len: usize = target.length();
    while (1 < len) {
        var last_swap_index: usize = 0;
        for (1..len) |i| {
            if (target.lessThanII(i, i - 1)) {
                target.swap(i, i - 1);
                last_swap_index = i;
            }
        }
        len = last_swap_index;
    }
}

/// シェイカーソート。
/// 前から後ろ、後ろから前を交互に繰り返す。
pub fn shakerSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;

    for (0..target.length() / 2) |i| {
        // 順方向
        for (i..target.length() - i - 1) |j| {
            if (target.lessThanII(j + 1, j)) {
                target.swap(j + 1, j);
            }
        }

        // 逆方向
        var j = target.length() - i - 1;
        while (j > i) : (j -= 1) {
            if (target.lessThanII(j, j - 1)) {
                target.swap(j, j - 1);
            }
        }
    }
}

/// シェイカーソート。
/// 前から後ろ、後ろから前を交互に繰り返す。
pub fn shakerSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;

    var top: usize = 0;
    var bottom = target.length() - 1;

    while (true) {
        // 順方向
        var last_swap_index = top;

        for (top..bottom) |i| {
            if (target.lessThanII(i + 1, i)) {
                target.swap(i + 1, i);
                last_swap_index = i;
            }
        }
        bottom = last_swap_index;

        if (top == bottom) {
            break;
        }

        // 逆方向
        last_swap_index = bottom;

        var i = bottom;
        while (i > top) : (i -= 1) {
            if (target.lessThanII(i, i - 1)) {
                target.swap(i, i - 1);
                last_swap_index = i;
            }
        }
        top = last_swap_index;

        if (top == bottom) {
            break;
        }
    }
}

/// 整数を1.3で割った整数を計算する。
fn combSortDivBy13(num: usize) usize {
    if (num < 2) return 1;
    const result = num * 10 / 13;
    if (result == 9 or result == 10) return 11;
    return result;
}

/// コムソート。
/// 比較する2つの間隔を開けてソートする。
pub fn combSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var gap = combSortDivBy13(target.length());
    while (true) : (gap = combSortDivBy13(gap)) {
        var len: usize = target.length();
        while (gap < len) {
            var last_swap_index: usize = 0;
            for (gap..len) |i| {
                if (target.lessThanII(i, i - gap)) {
                    target.swap(i, i - gap);
                    last_swap_index = i;
                }
            }
            len = last_swap_index;
        }

        if (gap < 2) break;
    }
}

/// 奇偶転置ソート。
/// 奇数番目と偶数番目、偶数番目と奇数番目のペア列を交互にソートする。
pub fn oddEvenSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    while (true) {
        var changed = false;

        {
            var i: usize = 1;
            while (i < target.length()) : (i += 2) {
                if (target.lessThanII(i, i - 1)) {
                    target.swap(i, i - 1);
                    changed = true;
                }
            }
        }

        {
            var i: usize = 2;
            while (i < target.length()) : (i += 2) {
                if (target.lessThanII(i, i - 1)) {
                    target.swap(i, i - 1);
                    changed = true;
                }
            }
        }

        if (!changed) {
            break;
        }
    }
}
