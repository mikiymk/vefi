const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../../root.zig");
const LoggedSortTarget = lib.algorithm.sort.LoggedSortTarget;

test {
    std.testing.refAllDecls(@This());
}

/// 選択ソート。
/// 最小の値を選択して先頭から配置する。
pub fn selectionSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        var min_index: usize = i;
        for (i + 1..target.length()) |j| {
            if (target.lessThanII(j, min_index)) {
                min_index = j;
            }
        }

        if (min_index != i) {
            target.swap(i, min_index);
        }
    }
}

/// ノームソート。
/// 位置を移動して前後の順序を並べる。
pub fn gnomeSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var i: usize = 1;
    while (i < target.length()) {
        if (target.lessThanII(i, i - 1)) {
            target.swap(i, i - 1);
            if (i == 1) i += 1 else i -= 1;
        } else {
            i += 1;
        }
    }
}

/// 挿入ソート。
/// 対象の値を適切な位置に配置する。
pub fn insertionSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        var j = i;
        while (0 < j and target.lessThanII(j, j - 1)) : (j -= 1) {
            target.swap(j, j - 1);
        }
    }
}

/// 挿入ソート。
/// 値を保持して、交換の代わりに移動を使用する。
pub fn insertionSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        const tmp = target.get(i);
        var j = i;
        while (0 < j and target.lessThanVI(tmp, j - 1)) : (j -= 1) {
            target.move(j, j - 1);
        }
        target.set(j, tmp);
    }
}

/// 二分挿入ソート。
/// 挿入ソートの挿入位置を二分探索で見つける。
pub fn binaryInsertionSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    for (1..target.length()) |i| {
        const pos = lib.algorithm.search.binarySearchRightmost(target, 0, i, i);
        // pos .. i-1 を右にシフトする。
        const tmp = target.get(i);
        var j = i;
        while (pos < j) : (j -= 1) {
            target.move(j, j - 1);
        }
        target.set(j, tmp);
    }
}

/// シェルソートの間隔を決める関数。
/// 案1. 2で割る (切り捨て)
fn shellSortGap1(num: usize) usize {
    return num / 2;
}
/// シェルソートの間隔を決める関数。
/// 案2. (3^k-1)/2
fn shellSortGap2(num: usize) usize {
    var pow_3: usize = 9; // 3^k
    var last_n: usize = 1;
    while (true) {
        const n = (pow_3 - 1) / 2;
        if (num <= n) return last_n;
        pow_3 *= 3;
        last_n = n;
    }

    return num / 3;
}
/// シェルソートの間隔を決める関数。
/// 案3. a(0)=1; a(k) = 4^k+3*2^(k-1)+1
fn shellSortGap3(num: usize) usize {
    var pow_2: usize = 1; // 2^(k-1)
    var pow_4: usize = 4; // 4^k
    var last_a_k: usize = 1; // 初期値は a(0) = 1
    while (true) {
        const a_k = pow_4 + 3 * pow_2 + 1;
        if (num <= a_k) return last_a_k;
        pow_2 *= 2;
        pow_4 *= 4;
        last_a_k = a_k;
    }
}

/// シェルソート。
/// 間隔を空けて挿入ソートをする。
/// シェルの間隔。
pub fn shellSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var gap = target.length();
    while (true) {
        gap = shellSortGap1(gap);
        for (0..target.length()) |i| {
            const tmp = target.get(i);
            var j = i;
            while (gap <= j and target.lessThanVI(tmp, j - gap)) : (j -= gap) {
                target.move(j, j - gap);
            }
            target.set(j, tmp);
        }

        if (gap < 2) break;
    }
}

/// シェルソート。
/// 間隔を空けて挿入ソートをする。
/// クヌースの間隔。
pub fn shellSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var gap = target.length();
    while (true) {
        gap = shellSortGap2(gap);
        for (0..target.length()) |i| {
            const tmp = target.get(i);
            var j = i;
            while (gap <= j and target.lessThanVI(tmp, j - gap)) : (j -= gap) {
                target.move(j, j - gap);
            }
            target.set(j, tmp);
        }

        if (gap < 2) break;
    }
}

/// シェルソート。
/// 間隔を空けて挿入ソートをする。
/// セッジウィックの間隔。
pub fn shellSort3(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var gap = target.length();
    while (true) {
        gap = shellSortGap3(gap);
        for (0..target.length()) |i| {
            const tmp = target.get(i);
            var j = i;
            while (gap <= j and target.lessThanVI(tmp, j - gap)) : (j -= gap) {
                target.move(j, j - gap);
            }
            target.set(j, tmp);
        }

        if (gap < 2) break;
    }
}
