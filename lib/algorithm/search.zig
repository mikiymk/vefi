const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const LoggedSortTarget = @import("sort/LoggedSortTarget.zig");

/// 右側線形探索。
/// [start, end) で S[i] < S[j] になる最小の j を見つけて返す。
pub fn linearSearchRightmost(target: *LoggedSortTarget, start: usize, end: usize, i: usize) usize {
    var n: usize = start;
    while (n < end and !target.lessThanII(i, n)) : (n += 1) {}
    return n;
}

/// 左側線形探索。
/// [start, end) で S[i] <= S[j] になる最小の j を見つけて返す。
pub fn linearSearchLeftmost(target: *LoggedSortTarget, start: usize, end: usize, i: usize) usize {
    var n: usize = start;
    while (n < end and target.lessThanII(n, i)) : (n += 1) {}
    return n;
}

/// 右側二分探索。
/// [start, end) で S[i] < S[j] になる最小の j を見つけて返す。
pub fn binarySearchRightmost(target: *LoggedSortTarget, start: usize, end: usize, i: usize) usize {
    var l = start;
    var r = end;
    while (l < r) {
        const m = (l + r) / 2;
        if (target.lessThanII(i, m)) { // S[i] < S[m] なら m か m より左にある。
            r = m;
        } else { // S[m] <= S[i] なら m より右にある。
            l = m + 1;
        }
    }

    return l;
}

/// 左側二分探索。
/// [start, end) で S[i] <= S[j] になる最小の j を見つけて返す。
pub fn binarySearchLeftmost(target: *LoggedSortTarget, start: usize, end: usize, i: usize) usize {
    var l = start;
    var r = end;
    while (l < r) {
        const m = (l + r) / 2;
        if (target.lessThanII(m, i)) { // S[m] < S[i] なら m より右にある。
            l = m + 1;
        } else { // S[i] <= S[m] なら m か m より左にある。
            r = m;
        }
    }

    return l;
}
