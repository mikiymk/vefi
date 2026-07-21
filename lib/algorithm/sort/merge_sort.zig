const std = @import("std");
const Allocator = std.mem.Allocator;

const lib = @import("../../root.zig");
const LoggedSortTarget = lib.algorithm.sort.LoggedSortTarget;

test {
    std.testing.refAllDecls(@This());
}

fn debug(src: std.builtin.SourceLocation, comptime format: []const u8, args: anytype) void {
    std.log.debug("{s}:{d}:{d} {s}: " ++ format, .{ src.file, src.line, src.column, src.fn_name } ++ args);
}

/// 要素を逆順にする。
fn reverse(target: *LoggedSortTarget, left: usize, right: usize) void {
    const size = right - left;
    const mid = size / 2;
    for (0..mid) |i| {
        target.swap(left + i, right - i - 1);
    }
}

/// 連続した2つのソート済み配列をマージする。
fn mergeSort1Merge(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize) !void {
    // 既にソートされている場合 (S[l_end] <= S[r_start]) はマージしない。
    if (!target.lessThanII(mid, mid - 1)) return;
    const buffer = try allocator.alloc(LoggedSortTarget.Type, end - start);
    defer allocator.free(buffer);

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

/// 範囲のあるマージソート。
fn mergeSort1Internal(allocator: Allocator, target: *LoggedSortTarget, start: usize, end: usize) !void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    try mergeSort1Internal(allocator, target, start, mid);
    try mergeSort1Internal(allocator, target, mid, end);

    // ソートした2つをマージする。
    try mergeSort1Merge(allocator, target, start, mid, end);
}

/// マージソート。
/// 分割して結合を繰り返す。
pub fn mergeSort1(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    try mergeSort1Internal(allocator, target, 0, target.length());
}

/// 連続した2つのソート済み配列をマージする。
fn mergeSort2Merge(target: *LoggedSortTarget, start: usize, mid: usize, end: usize, buffer: []LoggedSortTarget.Type) void {
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
fn mergeSort2Internal(target: *LoggedSortTarget, start: usize, end: usize, buffer: []LoggedSortTarget.Type) void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    mergeSort2Internal(target, start, mid, buffer);
    mergeSort2Internal(target, mid, end, buffer);

    // ソートした2つをマージする。
    mergeSort2Merge(target, start, mid, end, buffer);
}

/// マージソート。
/// 分割して結合を繰り返す。
/// 大きなバッファーを1回だけ作成する。
pub fn mergeSort2(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    const buffer = try allocator.alloc(LoggedSortTarget.Type, target.length());
    defer allocator.free(buffer);
    mergeSort2Internal(target, 0, target.length(), buffer);
}

/// 範囲内をn個だけ右方向にずらす。
/// 3回反転法を使う。
fn inPlaceMergeSort1RotateRight(target: *LoggedSortTarget, left: usize, right: usize, n: usize) void {
    reverse(target, left, right);
    reverse(target, left + n, right);
    reverse(target, left, left + n);
}

/// 連続した2つのソート済み配列をマージする。
fn inPlaceMergeSort1Merge(target: *LoggedSortTarget, start: usize, mid: usize, end: usize) void {
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
        inPlaceMergeSort1RotateRight(target, left, right, right_offset); // 1と同じものを使う
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += right_offset;
    }
}

/// 分割されたIn-Placeマージソート。
fn inPlaceMergeSort1Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    inPlaceMergeSort1Internal(target, start, mid);
    inPlaceMergeSort1Internal(target, mid, end);

    // ソートした2つをマージする。
    inPlaceMergeSort1Merge(target, start, mid, end);
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn inPlaceMergeSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    inPlaceMergeSort1Internal(target, 0, target.length());
}

/// 連続した2つのソート済み配列をマージする。
fn inPlaceMergeSort2Merge(target: *LoggedSortTarget, start: usize, mid: usize, end: usize) void {
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
        inPlaceMergeSort1RotateRight(target, left, right, right_offset); // 1と同じものを使う
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += right_offset;
    }
}

/// 分割されたIn-Placeマージソート。
fn inPlaceMergeSort2Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    inPlaceMergeSort2Internal(target, start, mid);
    inPlaceMergeSort2Internal(target, mid, end);

    // ソートした2つをマージする。
    inPlaceMergeSort2Merge(target, start, mid, end);
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn inPlaceMergeSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    inPlaceMergeSort2Internal(target, 0, target.length());
}

/// ユークリッド互除法で最大公約数を求める。
fn inPlaceMergeSort3Gcd(a: usize, b: usize) usize {
    return if (a == 0) b else inPlaceMergeSort3Gcd(b % a, a);
}

/// 範囲内をn個だけ右方向にずらす。
/// ジャグリングアルゴリズムを使う。
fn inPlaceMergeSort3RotateRight(target: *LoggedSortTarget, left: usize, right: usize, size: usize) void {
    const length = right - left;
    const move_left_size = length - size;
    const cycle_count = inPlaceMergeSort3Gcd(move_left_size, length);

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

/// 連続した2つのソート済み配列をマージする。
fn inPlaceMergeSort3Merge(target: *LoggedSortTarget, start: usize, mid: usize, end: usize) void {
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
        inPlaceMergeSort3RotateRight(target, left, right, right_offset); // 1と同じものを使う
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += right_offset;
    }
}

/// 連続した2つのソート済み配列をマージする。
/// 分割されたIn-Placeマージソート。
fn inPlaceMergeSort3Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end <= start + 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    inPlaceMergeSort3Internal(target, start, mid);
    inPlaceMergeSort3Internal(target, mid, end);

    // ソートした2つをマージする。
    inPlaceMergeSort3Merge(target, start, mid, end);
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn inPlaceMergeSort3(_: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    inPlaceMergeSort3Internal(target, 0, target.length());
}

// Tim Sort は整列した領域(run)ごとにマージする。
// https://github.com/python/cpython/blob/v2.3.7/Objects/listobject.c#L1670
// https://github.com/python/cpython/blob/v3.11.15/Objects/listobject.c#L2533

/// run の最小要素数を求める。
fn timSortMinRun1(length: usize) usize {
    // データ数を min run で割ったとき、2のべき乗か少し小さくなるように [32,64) で設定する。
    // 上位6ビット + それ以下が1以上なら +1

    var r: usize = 0;
    var n = length;
    while (n >= 64) {
        r = r | (n & 1);
        n = n >> 1;
    }
    return n + r;
}

/// run の最小要素数を求める。
fn timSortMinRun2(length: usize) usize {
    // データ数を min run で割ったとき、2のべき乗か少し小さくなるように [32,64) で設定する。
    // 上位6ビット + それ以下が1以上なら +1

    const n = @as(u6, @intCast(@bitSizeOf(usize) - @clz(length))) -| 6;
    const mask = @as(usize, 0b111111) << n;
    const remain_bits: usize = if (length & ~mask == 0) 0 else 1;

    return ((length & mask) >> n) + remain_bits;
}

const MIN_GALLOP: usize = 7;

/// 二分探索挿入ソート。
/// [start, sorted) の範囲がソート済み、 [sorted, end) の範囲が未ソート。
fn timSortBinaryInsertion(target: *LoggedSortTarget, start: usize, sorted: usize, end: usize) void {
    if (end <= start + 1) return;
    for (sorted..end) |i| {
        const pos = lib.algorithm.search.binarySearchRightmost(target, start, i, i);
        // pos .. i-1 を右にシフトする。
        const i_value = target.get(i);
        var j = i;
        while (pos < j) : (j -= 1) {
            target.move(j, j - 1);
        }
        target.set(j, i_value);
    }
}

/// 配列の領域
const Run = struct {
    start: usize,
    end: usize,

    fn len(self: @This()) usize {
        return self.end - self.start;
    }

    /// 文字列に変換する
    pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("Run({}-{})", .{ self.start, self.end });
    }
};

/// start から始まる整列した領域(run)を返す。
fn timSortRun(target: *LoggedSortTarget, start: usize, min_run: usize) Run {
    debug(@src(), "ランを作成 {}-", .{start});

    // 終端に達した場合はそこまで
    if (start + 1 == target.length()) {
        return .{ .start = start, .end = start + 1 };
    }

    // 既に並んでいる領域を求める。
    // target[start] > target[start + 1] の場合、降順のランを作成する。
    var i = start + 2;
    const descend = target.lessThanII(start + 1, start);
    if (descend) {
        while (i < target.length()) {
            // 降順ならば S[i - 1] > S[i] でない場合に終了する。
            // 安定性のため S[i - 1] == S[i] の場合も終了する。
            if (!target.lessThanII(i, i - 1)) break;
            i += 1;
        }
    } else {
        while (i < target.length()) {
            // 昇順ならば S[i - 1] <= S[i] でない場合に終了する。
            if (target.lessThanII(i, i - 1)) break;
            i += 1;
        }
    }

    // 降順の場合は逆転させる。
    debug(@src(), "昇順？ {} 終点 {}", .{ !descend, i });
    if (descend) {
        debug(@src(), "反転する {} {}", .{ start, i });
        reverse(target, start, i);
    }

    // 最小ランより小さい場合は二分挿入ソートで拡張する。
    if (i < start + min_run) {
        var end = start + min_run;
        debug(@src(), "延長する {} {}", .{ i, end });
        if (target.length() <= end) end = target.length();
        timSortBinaryInsertion(target, start, i, end);
        i = end;
    }

    return .{ .start = start, .end = i };
}

/// 二分探索で S[key] の値を挿入できる位置を見つける。
/// 戻り値 k は start <= k < end および S[k-1] < S[key] <= S[k] を満たす。
fn timSortGallopLeft(target: *LoggedSortTarget, key: usize, start: usize, end: usize, hint: usize) usize {
    lib.assert.assert(start <= end and start <= hint and hint < end);

    var left: usize = undefined;
    var right: usize = undefined;

    if (target.lessThanII(hint, key)) {
        // S[hint] < S[key]
        // gallop right, until S[hint + last_offset] < S[key] <= S[hint + offset]
        var offset: usize = 1;
        var last_offset: usize = 0;
        const max_offset = end - hint;
        while (offset < max_offset) {
            if (target.lessThanII(hint + offset, key)) {
                last_offset = offset;
                offset = offset * 2 + 1;
            } else {
                // S[key] <= S[hint + offset]
                break;
            }
        }
        if (max_offset < offset) {
            offset = max_offset;
        }

        left = hint + last_offset + 1;
        right = hint + offset;
    } else {
        // gallop left, until S[hint - offset] < S[key] <= a[hint - last_offset]
        const max_offset = hint - start + 1;
        var offset: usize = 1;
        var last_offset: usize = 0;
        while (offset < max_offset) {
            if (target.lessThanII(hint - offset, key)) {
                break;
            } else {
                // S[key] <= S[hint - ofs]
                last_offset = offset;
                offset = offset * 2 + 1;
            }
        }

        if (max_offset < offset) {
            offset = max_offset;
        }

        left = hint + 1 - offset;
        right = hint - last_offset;
    }

    lib.assert.assert(start <= left and left <= right and right <= end);
    lib.assert.assert(target.lessThanII(left, key) and !target.lessThanII(right, key)); // S[left] < S[key] <= S[right]

    return lib.algorithm.search.binarySearchLeftmost(target, left, right, key);
}

/// 二分探索で S[key] の値を挿入できる位置を見つける。
/// 戻り値 k は start <= k < end および S[k-1] <= S[key] < S[k] を満たす。
fn timSortGallopRight(target: *LoggedSortTarget, key: usize, start: usize, end: usize, hint: usize) usize {
    lib.assert.assert(start <= end and start <= hint and hint < end);

    var left: usize = undefined;
    var right: usize = undefined;

    if (target.lessThanII(key, hint)) {
        // S[key] < S[hint]
        // gallop left, until S[hint - offset] <= S[key] < S[hint - last_offset]
        var offset: usize = 1;
        var last_offset: usize = 0;
        const max_offset = hint - start + 1;
        while (offset < max_offset) {
            if (target.lessThanII(key, hint - offset)) {
                last_offset = offset;
                offset = offset * 2 + 1;
            } else {
                // S[hint - offset] <= S[key]
                break;
            }
        }
        if (max_offset < offset) {
            offset = max_offset;
        }

        left = hint + 1 - offset;
        right = hint - last_offset;
    } else {
        // gallop left, until S[hint + last_offset] <= S[key] < a[hint + offset]
        const max_offset = end - hint;
        var offset: usize = 1;
        var last_offset: usize = 0;
        while (offset < max_offset) {
            if (target.lessThanII(key, hint + offset)) {
                break;
            } else {
                // S[hint - offset] <= S[key]
                last_offset = offset;
                offset = offset * 2 + 1;
            }
        }

        if (max_offset < offset) {
            offset = max_offset;
        }

        left = hint + last_offset + 1;
        right = hint + offset;
    }

    lib.assert.assert(start <= left and left <= right and right <= end);
    lib.assert.assert(target.lessThanII(left, key) and !target.lessThanII(right, key)); // S[left] < S[key] <= S[right]

    return lib.algorithm.search.binarySearchLeftmost(target, left, right, key);
}

/// [start, mid) と [mid, end) をマージする。
/// (mid - start) < (end - mid) の場合。
fn timSortMergeLow(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize) !void {
    lib.assert.assert(mid - start < end - mid);

    // [start, mid) を一時配列に移す。
    const buffer_size = mid - start;
    const buffer = try target.getTemp(allocator, buffer_size);
    const buffer_end = buffer + buffer_size;
    defer target.freeTemp(allocator, buffer, buffer_size);
    for (0..buffer_size) |n| {
        target.move(buffer + n, start + n);
    }

    var min_gallop = MIN_GALLOP;

    var d_index = start;
    var a_index = buffer;
    var b_index = mid;

    target.move(d_index, b_index);
    d_index += 1;
    b_index += 1;

    if (b_index == end) {
        timSortMergeLowSucceed(target, d_index, a_index, buffer_end);
        return;
    }
    if (a_index + 1 == buffer_end) {
        timSortMergeLowCopyB(target, d_index, a_index, b_index, end);
        return;
    }

    while (true) {
        var a_count = 0;
        var b_count = 0;

        // 通常のコピー
        while (true) {
            if (target.lessThanII(b_index, a_index)) {
                target.move(d_index, b_index);
                d_index += 1;
                b_index += 1;

                a_count = 0;
                b_count += 1;

                if (b_index == end) {
                    timSortMergeLowSucceed(target, d_index, a_index, buffer_end);
                    return;
                }
                if (min_gallop <= b_count) {
                    break;
                }
            } else {
                target.move(d_index, a_index);
                d_index += 1;
                a_index += 1;

                a_count += 1;
                b_count = 0;

                if (a_index + 1 == buffer_end) {
                    timSortMergeLowCopyB(target, d_index, a_index, b_index, end);
                    return;
                }
                if (min_gallop <= a_count) {
                    break;
                }
            }
        }

        min_gallop += 1;

        while (true) {
            if (min_gallop > 1) min_gallop -= 1;

            // 左側のギャロッピング
            const a_gallop_count = timSortGallopRight(target, b_index, a_index, buffer_end, 0);
            for (a_index..a_gallop_count) |_| {
                target.move(d_index, a_index);
                d_index += 1;
                a_index += 1;
            }
            if (a_index + 1 == buffer_end) {
                timSortMergeLowCopyB(target, d_index, a_index, b_index, end);
                return;
            }
            if (a_index == buffer_end) {
                timSortMergeLowSucceed(target, d_index, a_index, buffer_end);
                return;
            }

            // 右側が止まった次は右側
            target.move(d_index, b_index);
            d_index += 1;
            b_index += 1;
            if (b_index == end) {
                timSortMergeLowSucceed(target, d_index, a_index, buffer_end);
                return;
            }

            // 右側のギャロッピング
            const b_gallop_count = timSortGallopLeft(target, a_index, b_index, end, 0);
            for (b_index..b_gallop_count) |_| {
                target.move(d_index, b_index);
                d_index += 1;
                b_index += 1;
            }
            if (b_index == end) {
                timSortMergeLowSucceed(target, d_index, a_index, buffer_end);
                return;
            }

            // 右側が止まった次は左側
            target.move(d_index, a_index);
            d_index += 1;
            a_index += 1;
            if (a_index + 1 == buffer_end) {
                timSortMergeLowCopyB(target, d_index, a_index, b_index, end);
                return;
            }

            // do {} while (acount >= MIN_GALLOP || bcount >= MIN_GALLOP);
            if (!(a_gallop_count >= MIN_GALLOP or b_gallop_count >= MIN_GALLOP)) {
                timSortMergeLowSucceed(target, d_index, a_index, buffer_end);
                return;
            }
        }
        min_gallop += 1;
    }
}

fn timSortMergeLowSucceed(target: *LoggedSortTarget, d_index: usize, a_index: usize, buffer_end: usize) void {
    if (a_index < buffer_end) {
        for (a_index..buffer_end, d_index..) |a, d| {
            target.move(d, a);
        }
    }
}

fn timSortMergeLowCopyB(target: *LoggedSortTarget, d_index: usize, a_index: usize, b_index: usize, end: usize) void {
    for (b_index..end) |_| {
        target.move(d_index, b_index);
        d_index += 1;
        b_index += 1;
    }
    target.move(d_index, a_index);
}

/// [start, mid) と [mid, end) をマージする。
/// (mid - start) >= (end - mid) の場合。
fn timSortMergeHigh(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize) !void {
    lib.assert.assert(end - mid <= mid - start);

    // [mid, end) を一時配列に移す。
    const buffer_size = end - mid;
    const buffer = try target.getTemp(allocator, buffer_size);
    const buffer_end = buffer + buffer_size;
    defer target.freeTemp(allocator, buffer, buffer_size);
    for (buffer..buffer_end, mid..) |n, m| {
        target.move(n, m);
    }

    var min_gallop = MIN_GALLOP;

    var d_index = end;
    var a_index = mid;
    var b_index = buffer_end;

    target.move(d_index - 1, a_index - 1);
    d_index -= 1;
    a_index -= 1;
    if (start == a_index) return timSortMergeHighSucceed(target, d_index, buffer, b_index);
    if (buffer + 1 == b_index) return timSortMergeHighCopyA(target, d_index, start, a_index, b_index);

    while (true) {
        var a_count = 0;
        var b_count = 0;

        // 通常のコピー
        while (true) {
            if (target.lessThanII(b_index - 1, a_index - 1)) {
                target.move(d_index - 1, a_index - 1);
                d_index -= 1;
                a_index -= 1;

                a_count += 1;
                b_count = 0;

                if (start == a_index) return timSortMergeHighSucceed(target, d_index, buffer, b_index);
                if (min_gallop <= b_count) break;
            } else {
                target.move(d_index - 1, b_index - 1);
                d_index -= 1;
                b_index -= 1;

                a_count = 0;
                b_count += 1;

                if (buffer + 1 == b_index) return timSortMergeHighCopyA(target, d_index, start, a_index, b_index);
                if (min_gallop <= a_count) break;
            }
        }

        min_gallop += 1;

        while (true) {
            if (min_gallop > 1) min_gallop -= 1;

            // 左側のギャロッピング
            const a_gallop_count = timSortGallopRight(target, b_index, mid, a_index, a_index - 1);
            for (0..a_index - a_gallop_count) |_| {
                target.move(d_index - 1, a_index - 1);
                d_index -= 1;
                a_index -= 1;
            }
            if (start == a_index) return timSortMergeHighSucceed(target, d_index, buffer, b_index);

            // 右側が止まった次は右側
            target.move(d_index - 1, b_index - 1);
            d_index -= 1;
            b_index -= 1;
            if (buffer + 1 == b_index) return timSortMergeHighCopyA(target, d_index, start, a_index, b_index);

            // 右側のギャロッピング
            const b_gallop_count = timSortGallopLeft(target, a_index, buffer, b_index, b_index - 1);
            for (0..b_gallop_count) |_| {
                target.move(d_index - 1, b_index - 1);
                d_index -= 1;
                b_index -= 1;
            }
            if (buffer + 1 == b_index) return timSortMergeHighCopyA(target, d_index, start, a_index, b_index);
            if (buffer == b_index) return timSortMergeHighSucceed(target, d_index, buffer, b_index);

            // 右側が止まった次は左側
            target.move(d_index - 1, a_index - 1);
            d_index -= 1;
            a_index -= 1;
            if (start == a_index) return timSortMergeHighSucceed(target, d_index, buffer, b_index);

            // do {} while (acount >= MIN_GALLOP || bcount >= MIN_GALLOP);
            if (!(a_gallop_count >= MIN_GALLOP or b_gallop_count >= MIN_GALLOP)) {
                return timSortMergeHighSucceed(target, d_index, buffer, b_index);
            }
        }
        min_gallop += 1;
    }
}

fn timSortMergeHighSucceed(target: *LoggedSortTarget, d_index: usize, buffer: usize, b_index: usize) void {
    for (buffer..b_index, d_index..) |b, d| {
        target.move(d, b);
    }
}

fn timSortMergeHighCopyA(target: *LoggedSortTarget, d_index: usize, start: usize, a_index: usize, b_index: usize) void {
    for (start..a_index) |_| {
        target.move(d_index - 1, a_index - 1);
        d_index -= 1;
        a_index -= 1;
    }
    target.move(d_index, b_index);
}

/// (start, mid] と (mid, end] をマージする。
fn timSortMergeAt(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize) !void {
    const a_start = start;
    const a_end = mid;
    const b_start = mid;
    const b_end = end;

    const l = timSortGallopLeft(target, b_start, a_start, a_end, 0);
    const r = timSortGallopRight(target, a_end - 1, b_start, b_end, b_end - b_start - 1);

    if (a_end - l < r - b_start) {
        try timSortMergeLow(allocator, target, l, mid, r);
    } else {
        try timSortMergeHigh(allocator, target, l, mid, r);
    }
}

/// ランのスタックが不変条件を満たすまでマージする。
fn timSortMergeCollapse(allocator: Allocator, target: *LoggedSortTarget, run_stack: *std.ArrayList(Run)) !void {
    while (1 < run_stack.items.len) {
        // { ... | z | y | x }

        var n = run_stack.items.len;
        if (2 < n and run_stack.items[n - 3].len() <= run_stack.items[n - 2].len() + run_stack.items[n - 1].len()) {
            if (run_stack.items[n - 3].len() < run_stack.items[n - 1].len()) {
                n -= 1;
            }
            try timSortMergeAt(allocator, target, run_stack, n - 2);
        } else if (run_stack.items[n - 2].len() <= run_stack.items[n - 1].len()) {
            try timSortMergeAt(allocator, target, run_stack, n - 2);
        } else {
            break;
        }
    }
}

/// ランのスタックが不変条件を満たすまでマージする。
fn timSortValidateRuns(allocator: Allocator, target: *LoggedSortTarget, run_stack: *std.ArrayList(struct { usize, usize })) !void {
    while (3 <= run_stack.items.len) {
        const x = run_stack.pop() orelse unreachable;
        const y = run_stack.pop() orelse unreachable;
        const z = run_stack.pop() orelse unreachable;

        const x_len = x.end - x.start;
        const y_len = y.end - y.start;
        const z_len = z.end - z.start;

        debug(@src(), "先頭ラン X {} Y {} Z {}", .{ x_len, y_len, z_len });

        // 並びはこうなるはず
        // { ... | z | y | x }
        if (!(x_len + y_len < z_len and x_len < y_len)) {
            if (x_len < z_len) {
                debug(@src(), "マージ Y {f} X {f}", .{ y, x });
                try timSortMergeAt(allocator, target, y.start, y.end, x.end);
                try run_stack.append(allocator, z);
                try run_stack.append(allocator, .{ .start = y.start, .end = x.end });
            } else {
                debug(@src(), "マージ Z {f} Y {f}", .{ z, y });
                try timSortMergeAt(allocator, target, z.start, z.end, y.end);
                try run_stack.append(allocator, .{ .start = z.start, .end = y.end });
                try run_stack.append(allocator, x);
            }
        } else {
            try run_stack.append(allocator, z);
            try run_stack.append(allocator, y);
            try run_stack.append(allocator, x);

            return;
        }
    }
}

/// ティムソート。
/// マージソートをもとに挿入ソートを使用して高速にする。
pub fn timSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    debug(@src(), "配列 {f}", .{target});
    if (target.length() < 2) return;

    const min_run = timSortMinRun2(target.length());
    debug(@src(), "最小 Run {}", .{min_run});

    var run_stack = std.ArrayList(Run).empty;
    defer run_stack.deinit(allocator);

    var run = Run{ .start = 0, .end = 0 };

    while (run.end < target.length()) {
        // ランを追加する。
        run = timSortRun(target, run.end, min_run);
        debug(@src(), "{f}", .{run});
        try run_stack.append(allocator, run);

        // 不変条件 (x + y < z and x < y) を満たすようにマージする。
        try timSortMergeCollapse(allocator, target, &run_stack);

        debug(@src(), "ラン: {any}", .{run_stack.items});
    }

    // 残りを1つのランになるまでマージする。
    while (2 <= run_stack.items.len) {
        const x = run_stack.pop() orelse unreachable;
        const y = run_stack.pop() orelse unreachable;
        debug(@src(), "マージ Y {f} X {f}", .{ y, x });
        try timSortMergeAt(allocator, target, y.start, y.end, x.end);
        try run_stack.append(allocator, .{ .start = y.start, .end = x.end });

        debug(@src(), "ラン: {any}", .{run_stack.items});
    }
}
