const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../../root.zig");
const LoggedSortTarget = lib.algorithm.sort.LoggedSortTarget;

test {
    std.testing.refAllDecls(@This());
}

/// 要素を逆順にする。
fn reverse(target: *LoggedSortTarget, left: usize, right: usize) void {
    const size = right - left;
    const mid = size / 2;
    for (0..mid) |i| {
        target.swap(left + i, right - i - 1);
    }
}

fn mergeSortMerge(target: *LoggedSortTarget, start: usize, mid: usize, end: usize, buffer: []LoggedSortTarget.Type) void {
    // 既にソートされている場合 (S[l_end] <= S[r_start]) はマージしない。
    if (!target.lessThanII(mid, mid - 1)) return;

    var left = start;
    var right = mid;

    var i: usize = 0;

    while (left < mid and right < end) {
        if (target.lessThanII(right, left)) {
            buffer[i] = target.get(right);
            right += 1;
        } else {
            buffer[i] = target.get(left);
            left += 1;
        }
        i += 1;
    }

    // 残りを入れる
    while (left < mid) {
        buffer[i] = target.get(left);
        left += 1;
        i += 1;
    }
    while (right < end) {
        buffer[i] = target.get(right);
        right += 1;
        i += 1;
    }

    // 戻す
    for (0..i) |j| {
        target.set(start + j, buffer[j]);
    }
}

/// 分割されたマージソート。
fn mergeSortInternal(target: *LoggedSortTarget, start: usize, end: usize, buffer: []LoggedSortTarget.Type) void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    mergeSortInternal(target, start, mid, buffer);
    mergeSortInternal(target, mid, end, buffer);
    // ソートした2つをマージする。
    mergeSortMerge(target, start, mid, end, buffer);
}

/// マージソート。
/// 分割して結合を繰り返す。
pub fn mergeSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    const buffer = try allocator.alloc(LoggedSortTarget.Type, target.length());
    defer allocator.free(buffer);
    mergeSortInternal(target, 0, target.length(), buffer);
}

/// 範囲内をn個だけ右方向にずらす。
fn mergeSortInPlace1RotateRight(target: *LoggedSortTarget, left: usize, right: usize, n: usize) void {
    reverse(target, left, right);
    reverse(target, left + n, right);
    reverse(target, left, left + n);
}

/// 分割されたIn-Placeマージソート。
fn mergeSortInPlace1Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    mergeSortInPlace1Internal(target, start, mid);
    mergeSortInPlace1Internal(target, mid, end);

    // ソートした2つをマージする。
    var left = start;
    var right = mid;
    while (true) {
        // 1. 左を進める
        left = lib.algorithm.search.linearSearchRightmost(target, left, right, right);
        // 2. 左が終わりなら終了
        if (left == right) break;
        // 3. 右を進める
        const new_right = lib.algorithm.search.linearSearchLeftmost(target, right, end, left);
        const right_offset = new_right - right;
        right = new_right;
        // 4. 右回転
        mergeSortInPlace1RotateRight(target, left, right, right_offset); // 1と同じものを使う
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += right_offset;
    }
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn mergeSortInPlace1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    mergeSortInPlace1Internal(target, 0, target.length());
}

/// 分割されたIn-Placeマージソート。
fn mergeSortInPlace2Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    mergeSortInPlace2Internal(target, start, mid);
    mergeSortInPlace2Internal(target, mid, end);

    // ソートした2つをマージする。
    var left = start;
    var right = mid;
    while (true) {
        // 1. 左を進める
        left = lib.algorithm.search.binarySearchRightmost(target, left, right, right);
        // 2. 左が終わりなら終了
        if (left == right) break;
        // 3. 右を進める
        const new_right = lib.algorithm.search.binarySearchLeftmost(target, right, end, left);
        const right_offset = new_right - right;
        right = new_right;
        // 4. 右回転
        mergeSortInPlace1RotateRight(target, left, right, right_offset); // 1と同じものを使う
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += right_offset;
    }
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn mergeSortInPlace2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    mergeSortInPlace2Internal(target, 0, target.length());
}

/// ユークリッド互除法で最大公約数を求める。
fn mergeSortInPlace3Gcd(a: usize, b: usize) usize {
    return if (a == 0) b else mergeSortInPlace3Gcd(b % a, a);
}

/// 範囲内をn個だけ右方向にずらす。
/// ジャグリングアルゴリズムを使う。
fn mergeSortInPlace3RotateRight(target: *LoggedSortTarget, left: usize, right: usize, size: usize) void {
    const length = right - left;
    const move_left_size = length - size;
    const cycle_count = mergeSortInPlace3Gcd(move_left_size, length);

    for (0..cycle_count) |i| {
        const tmp = target.get(left + i);
        var current_index = i;
        var next_index: usize = undefined;
        while (true) {
            next_index = (current_index + move_left_size) % length;
            if (next_index == i) break;
            target.move(left + current_index, left + next_index);
            current_index = next_index;
        }
        target.set(left + current_index, tmp);
    }
}

/// 分割されたIn-Placeマージソート。
fn mergeSortInPlace3Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    mergeSortInPlace3Internal(target, start, mid);
    mergeSortInPlace3Internal(target, mid, end);

    // ソートした2つをマージする。
    var left = start;
    var right = mid;
    while (true) {
        // 1. 左を進める
        left = lib.algorithm.search.binarySearchRightmost(target, left, right, right);
        // 2. 左が終わりなら終了
        if (left == right) break;
        // 3. 右を進める
        const new_right = lib.algorithm.search.binarySearchLeftmost(target, right, end, left);
        const right_offset = new_right - right;
        right = new_right;
        // 4. 右回転
        mergeSortInPlace3RotateRight(target, left, right, right_offset); // 1と同じものを使う
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += right_offset;
    }
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn mergeSortInPlace3(_: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    mergeSortInPlace3Internal(target, 0, target.length());
}

// Tim Sort は整列した領域(run)ごとにマージする。
// https://github.com/python/cpython/blob/v2.3.7/Objects/listobject.c#L1670

/// run の最小要素数を求める。
fn timSortMinRun(length: usize) usize {
    // デバッグ用
    // if (true) return 1;
    // データ数を min run で割ったとき、2のべき乗か少し小さくなるように [32,64) で設定する。
    // 上位6ビット + それ以下が1以上なら +1
    var n: u6 = @intCast(@bitSizeOf(usize) - @clz(length));
    if (n < 6) {
        n = 0;
    } else {
        n -= 6;
    }
    const mask = @as(usize, 0b111111) << n;

    const remain_bits: usize = if (length & ~mask == 0) 0 else 1;
    return ((length & mask) >> n) + remain_bits;
}

/// (start, end] の範囲を二分挿入ソートする。
pub fn timSortBinaryInsertion(target: *LoggedSortTarget, start: usize, sorted: usize, end: usize) void {
    if (end <= start + 1) return;
    for (sorted..end) |i| {
        const pos = lib.algorithm.search.binarySearchRightmost(target, start, i, i);
        // pos .. i-1 を右にシフトする。
        debug("{any} 作成ラン 延長 探索 {}", .{ target.slice, pos });
        debug("{any} 作成ラン 延長 シフト {} - {}", .{ target.slice, pos, i });
        const i_value = target.get(i);
        var j = i;
        while (pos < j) : (j -= 1) {
            target.move(j, j - 1);
        }
        target.set(j, i_value);
    }
}

/// start から始まる整列した領域(run)の末尾を返す。
fn timSortRun(target: *LoggedSortTarget, start: usize, min_run: usize) usize {
    debug("作成ラン 起点 {}", .{start});
    if (start + 1 == target.length()) return start + 1;
    const ascend: bool = target.lessThanII(start, start + 1);
    var i = start + 2;
    while (i < target.length()) {
        if (ascend == target.lessThanII(i, i - 1)) {
            // 次の場合に終了する。
            // a. 昇順ならば S[i - 1] <= S[i] (= !(S[i - 1] > S[i])) でない場合
            // b. 降順ならば S[i - 1] > S[i] でない場合
            break;
        }
        i += 1;
    }

    debug("昇順？ {} 終点 {}", .{ ascend, i });

    if (!ascend) { // 降順の場合は逆転させる。
        debug("反転する {} {}", .{ start, i });
        reverse(target, start, i);
        debug("配列: {any}", .{target.slice});
    }

    if (i < start + min_run) {
        // min run より小さい場合は二分挿入ソートで拡張する。
        var end = start + min_run;
        debug("延長する {} {}", .{ i, end });
        if (target.length() <= end) end = target.length();
        timSortBinaryInsertion(target, start, i, end);
        i = end;
        debug("配列: {any}", .{target.slice});
    }

    return i;
}

/// 二分探索で左端を見つける。
/// S[j] < S[i] である最大の j を (start, end] で見つける。
fn timSortGallopLeft(target: *LoggedSortTarget, start: usize, end: usize, i: usize) usize {
    var prev: usize = 0;
    var curr: usize = 1;
    while (start + curr < end and target.lessThanII(start + curr, i)) {
        prev = curr;
        curr *= 2;
    }

    return lib.algorithm.search.binarySearchLeftmost(target, start + prev, @min(start + curr, end), i);
}

// 二分探索で右端を見つける。
// S[i] < S[j] である最小の j を (start, end] で見つける。
fn timSortGallopRight(target: *LoggedSortTarget, start: usize, end: usize, i: usize) usize {
    var prev: usize = 0;
    var curr: usize = 1;
    while (start + curr < end and target.lessThanII(i, end - curr)) {
        prev = curr;
        curr *= 2;
    }
    return lib.algorithm.search.binarySearchRightmost(target, @max(end -| curr, start), end -| prev, i);
}

/// [start, mid) と [mid, end) をマージする。
/// (mid - start) < (end - mid) の場合。
fn timSortMergeLow(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize) !void {
    // [start, mid) を一時配列に移す。
    const buffer = try allocator.alloc(LoggedSortTarget.Type, mid - start);
    for (buffer, 0..) |*i, n| {
        i.* = target.get(start + n);
    }

    var left: usize = 0;
    var right = mid;
    var i = start;

    var left_count: usize = 0;
    var right_count: usize = 0;
    const min_gallop = 7;

    while (left < buffer.len and right < end) {
        // B[l] <= S[r] なら B[l] 、それ以外で S[r] が先。
        if (target.lessThanIV(right, buffer[left])) {
            target.move(i, right);
            right += 1;

            left_count = 0;
            right_count += 1;
        } else {
            target.set(i, buffer[left]);
            left += 1;

            left_count += 1;
            right_count = 0;
        }
        i += 1;

        if (min_gallop < left_count) {
            // 左側をギャロッピング
            const left_length = b: {
                // S[j] <= S[r] である最大の j を [left, buffer.len] で見つける。
                var prev: usize = 0;
                var curr: usize = 1;
                while (left + curr < buffer.len and target.lessThanVI(buffer[left + curr], right)) {
                    prev = curr;
                    curr *= 2;
                }

                var l = left + prev;
                var r = @min(left + curr, buffer.len);
                while (l < r) {
                    const m = (l + r) / 2;
                    // !(S[r] < B[m]) == S[r] >= B[m]
                    if (!target.lessThanIV(right, buffer[m])) {
                        l = m + 1;
                    } else {
                        r = m;
                    }
                }
                break :b l;
            };

            while (left < left_length) {
                target.set(i, buffer[left]);
                left += 1;
                i += 1;
            }

            left_count = 0;
        } else if (min_gallop < right_count) {
            // 右側をギャロッピング
            const right_length = b: {
                // S[j] < S[r] である最大の j を [left, buffer.len] で見つける。
                var prev: usize = 0;
                var curr: usize = 1;
                while (right + curr < end and target.lessThanIV(right + curr, buffer[left])) {
                    prev = curr;
                    curr *= 2;
                }

                var l = right + prev;
                var r = @min(right + curr, end);
                while (l < r) {
                    const m = (l + r) / 2;
                    if (target.lessThanIV(m, buffer[left])) {
                        l = m + 1;
                    } else {
                        r = m;
                    }
                }
                break :b l;
            };

            while (right < right_length) {
                target.move(i, right);
                right += 1;
                i += 1;
            }

            right_count = 0;
        }
    }

    // バッファの残りを入れる。
    // 右側のみの場合はそのまま。
    while (left < buffer.len) {
        target.set(i, buffer[left]);
        left += 1;
        i += 1;
    }
}

/// [start, mid) と [mid, end) をマージする。
/// (mid - start) >= (end - mid) の場合。
fn timSortMergeHigh(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize) !void {
    // [mid, end) を一時配列に移す。
    const buffer = try allocator.alloc(LoggedSortTarget.Type, end - mid);
    for (buffer, 0..) |*i, n| {
        i.* = target.get(mid + n);
    }

    // 右からマージする。
    var left = mid;
    var right = buffer.len;
    var i = end;

    while (start < left and 0 < right) {
        // S[r] < S[l] なら S[l] 、それ以外で S[r] が右。
        if (target.lessThanVI(buffer[right - 1], left - 1)) {
            target.move(i - 1, left - 1);
            left -= 1;
        } else {
            target.set(i - 1, buffer[right - 1]);
            right -= 1;
        }
        i -= 1;
    }

    // バッファの残りを入れる。
    // 左側が残った場合はそのまま。
    while (0 < right) {
        target.set(i - 1, buffer[right - 1]);
        right -= 1;
        i -= 1;
    }
}

/// (start, mid] と (mid, end] をマージする。
fn timSortMerge(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize) !void {
    // const l = start;
    // const r = end;
    const l = timSortGallopLeft(target, start, mid, mid);
    const r = timSortGallopRight(target, mid, end, mid - 1);
    debug("ギャロップ 左側 {} -> {} 右側 {} -> {}", .{ start, l, end, r });
    debug("左側範囲 {}-{}({}) 右側範囲 {}-{}({})", .{ l, mid, mid - l, mid, r, r - mid });

    if (mid - l < r - mid) {
        debug("左側が小さい", .{});
        try timSortMergeLow(allocator, target, l, mid, r);
    } else {
        debug("右側が小さい", .{});
        try timSortMergeHigh(allocator, target, l, mid, r);
    }
}

/// ランのスタックが不変条件を満たすまでマージする。
fn timSortValidateRuns(allocator: Allocator, target: *LoggedSortTarget, run_stack: *std.ArrayList(struct { usize, usize })) !void {
    while (3 <= run_stack.items.len) {
        const x_start, const x_end = run_stack.pop() orelse unreachable;
        const y_start, const y_end = run_stack.pop() orelse unreachable;
        const z_start, const z_end = run_stack.pop() orelse unreachable;

        const x = x_end - x_start;
        const y = y_end - y_start;
        const z = z_end - z_start;

        debug("先頭ラン X {} Y {} Z {}", .{ x, y, z });

        // 並びはこうなるはず
        // { ... | z | y | x }
        if (!(x + y < z and x < y)) {
            if (x < z) {
                debug("マージ Y {}-{} X {}-{}", .{ y_start, y_end, x_start, x_end });
                try timSortMerge(allocator, target, y_start, y_end, x_end);
                try run_stack.append(allocator, .{ z_start, z_end });
                try run_stack.append(allocator, .{ y_start, x_end });
            } else {
                debug("マージ Z {}-{} Y {}-{}", .{ z_start, z_end, y_start, y_end });
                try timSortMerge(allocator, target, z_start, z_end, y_end);
                try run_stack.append(allocator, .{ z_start, y_end });
                try run_stack.append(allocator, .{ x_start, x_end });
            }
        } else {
            try run_stack.append(allocator, .{ z_start, z_end });
            try run_stack.append(allocator, .{ y_start, y_end });
            try run_stack.append(allocator, .{ x_start, x_end });

            return;
        }
    }
}

/// ティムソート。
/// マージソートをもとに挿入ソートを使用して高速にする。
pub fn timSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    if (target.length() < 2) return;

    const min_run = timSortMinRun(target.length());
    debug("配列 {any}", .{target.slice});
    debug("最小 Run {}", .{min_run});
    var run_stack = std.ArrayList(struct { usize, usize }).empty;
    defer run_stack.deinit(allocator);

    var run_start: usize = 0;
    var run_end: usize = 0;

    while (run_end < target.length()) {
        // ランを追加する。
        run_start = run_end;
        run_end = timSortRun(target, run_start, min_run);
        debug("配列 {any}", .{target.slice});
        debug("ラン 範囲 {} {}", .{ run_start, run_end });
        try run_stack.append(allocator, .{ run_start, run_end });

        // 不変条件 (x + y < z and x < y) を満たすようにマージする。
        try timSortValidateRuns(allocator, target, &run_stack);

        debug("配列: {any}", .{target.slice});
        debug("ラン: {any}", .{run_stack.items});
    }

    // 残りを1つのランになるまでマージする。
    while (2 <= run_stack.items.len) {
        const x_start, const x_end = run_stack.pop() orelse unreachable;
        const y_start, const y_end = run_stack.pop() orelse unreachable;
        debug("マージ Y {}-{} X {}-{}", .{ y_start, y_end, x_start, x_end });
        try timSortMerge(allocator, target, y_start, y_end, x_end);
        try run_stack.append(allocator, .{ y_start, x_end });

        debug("配列: {any}", .{target.slice});
        debug("ラン: {any}", .{run_stack.items});
    }
}
