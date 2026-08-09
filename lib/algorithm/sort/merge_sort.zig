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

fn isSorted(target: LoggedSortTarget, start: usize, end: usize) bool {
    lib.assert.assert(start <= end);
    if (end - start <= 1) {
        return true;
    }

    for (start..end - 1) |i| {
        if (!(target.slice[i].v <= target.slice[i + 1].v)) {
            return false;
        }
    }

    return true;
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
// https://github.com/python/cpython/blob/v3.10.20/Objects/listobject.c#L2221
// https://github.com/openjdk/jdk/blob/jdk-28%2B8/src/java.base/share/classes/java/util/TimSort.java

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
    if (descend) {
        reverse(target, start, i);
    }

    // 最小ランより小さい場合は二分挿入ソートで拡張する。
    if (i < start + min_run) {
        var end = start + min_run;
        if (target.length() <= end) end = target.length();
        timSortBinaryInsertion(target, start, i, end);
        i = end;
    }

    return .{ .start = start, .end = i };
}

/// 二分探索で [start, end] の範囲から S[key] の値を挿入できる位置を見つける。
/// 戻り値 k は S[start-1] = -∞, S[end] = ∞ とした場合に S[k-1] < S[key] <= S[k] を満たす。
/// hint は start <= hint < end で、結果に近いほど計算量が少なくなる。
fn timSortGallopLeft(target: *LoggedSortTarget, key: usize, start: usize, end: usize, hint: usize) usize {
    lib.assert.assert(start < end);
    lib.assert.assert(start <= hint and hint < end);

    var left: usize = undefined;
    var right: usize = undefined;
    if (target.lessThanII(hint, key)) { // S[hint] < S[key]
        const max_offset = end - hint;
        var prev_offset: usize = 0;
        var offset: usize = 1;
        while (offset < max_offset and target.lessThanII(hint + offset, key)) {
            prev_offset = offset;
            offset = offset *| 2 + 1;
        }
        if (max_offset < offset)
            offset = max_offset;

        left = hint + prev_offset + 1;
        right = hint + offset;
    } else { // S[key] <= S[hint]
        const max_offset = hint - start + 1;
        var prev_offset: usize = 0;
        var offset: usize = 1;
        while (offset < max_offset and !target.lessThanII(hint - offset, key)) {
            prev_offset = offset;
            offset = offset *| 2 + 1;
        }
        if (max_offset < offset)
            offset = max_offset;

        left = hint + 1 - offset;
        right = hint - prev_offset;
    }

    lib.assert.assert(start <= left and left <= right and right <= end);
    return lib.algorithm.search.binarySearchLeftmost(target, left, right, key);
}

/// 二分探索で [start, end] の範囲から S[key] の値を挿入できる位置を見つける。
/// 戻り値 k は S[start-1] = -∞, S[end] = ∞ とした場合に S[k-1] <= S[key] < S[k] を満たす。
/// hint は start <= hint < end で、結果に近いほど計算量が少なくなる。
fn timSortGallopRight(target: *LoggedSortTarget, key: usize, start: usize, end: usize, hint: usize) usize {
    lib.assert.assert(start < end);
    lib.assert.assert(start <= hint and hint < end);

    var left: usize = undefined;
    var right: usize = undefined;
    if (target.lessThanII(key, hint)) { // S[key] < S[hint]
        const max_offset = hint - start + 1;
        var prev_offset: usize = 0;
        var offset: usize = 1;
        while (offset < max_offset and target.lessThanII(key, hint - offset)) {
            prev_offset = offset;
            offset = offset *| 2 + 1;
        }
        if (max_offset < offset)
            offset = max_offset;

        left = hint + 1 - offset;
        right = hint - prev_offset;
    } else { // S[hint] <= S[key]
        const max_offset = end - hint;
        var prev_offset: usize = 0;
        var offset: usize = 1;
        while (offset < max_offset and !target.lessThanII(key, hint + offset)) {
            prev_offset = offset;
            offset = offset *| 2 + 1;
        }
        if (max_offset < offset)
            offset = max_offset;

        left = hint + prev_offset + 1;
        right = hint + offset;
    }

    lib.assert.assert(start <= left and left <= right and right <= end);
    return lib.algorithm.search.binarySearchRightmost(target, left, right, key);
}

test "gallop left and right" {
    const TestCase = struct {
        slice: []const usize,
        k: usize,
        s: usize,
        e: usize,
        expected: usize,
    };

    var target = LoggedSortTarget.empty;
    const allocator = std.testing.allocator;
    defer target.deinit(allocator);

    const cases_l = [_]TestCase{
        .{ .slice = &.{ 0, 2, 4, 6, 8 }, .k = 0, .s = 1, .e = 5, .expected = 1 },
        .{ .slice = &.{ 4, 2, 4, 6, 8 }, .k = 0, .s = 1, .e = 5, .expected = 2 },
        .{ .slice = &.{ 5, 2, 4, 6, 8 }, .k = 0, .s = 1, .e = 5, .expected = 3 },
        .{ .slice = &.{ 9, 2, 4, 6, 8 }, .k = 0, .s = 1, .e = 5, .expected = 5 },
        .{ .slice = &.{ 3, 1, 3, 3, 5 }, .k = 0, .s = 1, .e = 5, .expected = 2 },
        .{ .slice = &.{ 1, 3, 5, 7, 4 }, .k = 4, .s = 0, .e = 4, .expected = 2 },
        .{ .slice = &.{ 1, 3, 5, 7, 5 }, .k = 4, .s = 0, .e = 4, .expected = 2 },
    };
    for (cases_l) |c| {
        try target.resize(allocator, c.slice.len);
        for (target.slice, c.slice) |*a, b| {
            a.v = b;
        }
        // std.debug.print("{any}\n", .{c});
        for (c.s..c.e) |hint| {
            try lib.testing.expect(timSortGallopLeft(&target, c.k, c.s, c.e, hint)).is(c.expected);
        }
    }

    const cases_r = [_]TestCase{
        .{ .slice = &.{ 0, 2, 4, 6, 8 }, .k = 0, .s = 1, .e = 5, .expected = 1 },
        .{ .slice = &.{ 4, 2, 4, 6, 8 }, .k = 0, .s = 1, .e = 5, .expected = 3 },
        .{ .slice = &.{ 5, 2, 4, 6, 8 }, .k = 0, .s = 1, .e = 5, .expected = 3 },
        .{ .slice = &.{ 9, 2, 4, 6, 8 }, .k = 0, .s = 1, .e = 5, .expected = 5 },
        .{ .slice = &.{ 3, 1, 3, 3, 5 }, .k = 0, .s = 1, .e = 5, .expected = 4 },
        .{ .slice = &.{ 1, 3, 5, 7, 4 }, .k = 4, .s = 0, .e = 4, .expected = 2 },
        .{ .slice = &.{ 1, 3, 5, 7, 5 }, .k = 4, .s = 0, .e = 4, .expected = 3 },
    };
    for (cases_r) |c| {
        try target.resize(allocator, c.slice.len);
        for (target.slice, c.slice) |*a, b| {
            a.v = b;
        }
        // std.debug.print("{any}\n", .{c});
        for (c.s..c.e) |hint| {
            try lib.testing.expect(timSortGallopRight(&target, c.k, c.s, c.e, hint)).is(c.expected);
        }
    }
}

/// [start, mid) と [mid, end) をマージする。
/// (mid - start) < (end - mid) の場合。
fn timSortMergeLow(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize, mg: *usize) !void {
    // 配列1を一時配列に移す。
    const buffer_length = mid - start;
    const buffer = try target.getTemp(allocator, buffer_length);
    const buffer_end = buffer + buffer_length;
    defer target.freeTemp(allocator, buffer, buffer_length);
    target.copy(buffer, start, buffer_length);

    var cursor1 = buffer;
    var cursor2 = mid;
    var dest = start;

    // 右側の左端は左端に
    target.move(dest, cursor2);
    dest += 1;
    cursor2 += 1;
    if (end - cursor2 == 0) {
        target.copy(dest, cursor1, buffer_end - cursor1);
        return;
    } else if (buffer_end - cursor1 == 1) {
        target.copy(dest, cursor2, end - cursor2);
        target.move(dest + end - cursor2, cursor1);
        return;
    }

    var minGallop = mg.*;

    outer: while (true) {
        var count1: usize = 0;
        var count2: usize = 0;

        while (true) {
            // 通常動作
            lib.assert.assert(buffer_end - cursor1 > 1);
            lib.assert.assert(end - cursor2 > 0);
            if (target.lessThanII(cursor2, cursor1)) {
                target.move(dest, cursor2);
                dest += 1;
                cursor2 += 1;

                count2 += 1;
                count1 = 0;

                if (end - cursor2 == 0)
                    break :outer;
            } else {
                target.move(dest, cursor1);
                dest += 1;
                cursor1 += 1;

                count1 += 1;
                count2 = 0;

                if (buffer_end - cursor1 == 1)
                    break :outer;
            }

            if (minGallop <= count1 or minGallop <= count2) break;
        }

        while (true) {
            // ギャロップ動作
            lib.assert.assert(buffer_end - cursor1 > 1);
            lib.assert.assert(end - cursor2 > 0);
            count1 = timSortGallopRight(target, cursor2, cursor1, buffer_end, cursor1) - cursor1;
            if (count1 != 0) {
                target.copy(dest, cursor1, count1);
                dest += count1;
                cursor1 += count1;
                if (buffer_end - cursor1 <= 1) // len1 == 1 or len1 == 0
                    break :outer;
            }

            target.move(dest, cursor2);
            dest += 1;
            cursor2 += 1;
            if (end - cursor2 == 0)
                break :outer;

            count2 = timSortGallopLeft(target, cursor1, cursor2, end, cursor2) - cursor2;
            if (count2 != 0) {
                target.copy(dest, cursor2, count2);
                dest += count2;
                cursor2 += count2;
                if (end - cursor2 == 0)
                    break :outer;
            }

            target.move(dest, cursor1);
            dest += 1;
            cursor1 += 1;
            if (buffer_end - cursor1 == 1)
                break :outer;

            minGallop -= 1;
            if (count1 < MIN_GALLOP and count2 < MIN_GALLOP) break;
        }
        if (minGallop < 0)
            minGallop = 0;
        minGallop += 2;
    } // outer

    mg.* = if (minGallop < 1) 1 else minGallop;

    // 最後に残ったものを詰める
    if (buffer_end - cursor1 == 1) {
        lib.assert.assert(end - cursor2 > 0);
        target.copy(dest, cursor2, end - cursor2);
        // 左側の右端は右端に
        target.move(dest + end - cursor2, cursor1);
    } else {
        lib.assert.assert(end - cursor2 == 0);
        lib.assert.assert(buffer_end - cursor1 > 1);
        target.copy(dest, cursor1, buffer_end - cursor1);
    }
}

test timSortMergeLow {
    const allocator = std.testing.allocator;
    var target = LoggedSortTarget.empty;
    defer target.deinit(allocator);

    try target.resize(allocator, 200);
    for (0..50) |i| target.slice[i].v = i + 50;
    for (50..100) |i| target.slice[i].v = i + 100;
    for (100..150) |i| target.slice[i].v = i - 100;
    for (150..200) |i| target.slice[i].v = i - 50;
    var min_gallop: usize = 7;
    try timSortMergeLow(allocator, &target, 0, 100, 200, &min_gallop);
    try lib.testing.expect(target.isSorted()).is(true);
}

/// [start, mid) と [mid, end) をマージする。
/// (mid - start) >= (end - mid) の場合。
fn timSortMergeHigh(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize, mg: *usize) !void {
    // 配列2を一時配列に移す。
    const buffer_length = end - mid;
    const buffer = try target.getTemp(allocator, buffer_length);
    const buffer_end = buffer + buffer_length;
    defer target.freeTemp(allocator, buffer, buffer_length);
    target.copy(buffer, mid, buffer_length);

    var len1 = mid - start;
    var len2 = end - mid;

    var cursor1 = mid;
    var cursor2 = buffer_end;
    var dest = end;

    std.debug.print("s {} m {} e {} b {} be {}\n", .{ start, mid, end, buffer, buffer_end });
    std.debug.print("l1 {} l2 {} c1 {} c2 {} d {}\n", .{ len1, len2, cursor1, cursor2, dest });

    lib.assert.assert(len1 == cursor1 - start);
    lib.assert.assert(len2 == cursor2 - buffer);

    // 左側の右端は右端に
    cursor1 -= 1;
    dest -= 1;
    target.move(dest, cursor1);
    len1 -= 1;
    if (len1 == 0) {
        target.copy(dest - 1, buffer, len2);
        return;
    } else if (len2 == 1) {
        dest -= len1;
        cursor1 -= len1;
        target.copy(dest, cursor1, len1);
        target.move(dest - 1, cursor2 - 1);
        return;
    }

    lib.assert.assert(len1 == cursor1 - start);
    lib.assert.assert(len2 == cursor2 - buffer);

    var minGallop = mg.*;

    outer: while (true) {
        var count1: usize = 0;
        var count2: usize = 0;
        std.debug.print("l1 {} l2 {} c1 {} c2 {} d {}\n", .{ len1, len2, cursor1, cursor2, dest });

        while (true) {
            // 通常動作
            lib.assert.assert(len1 > 0);
            lib.assert.assert(len2 > 1);

            if (target.lessThanII(cursor2 - 1, cursor1 - 1)) {
                cursor1 -= 1;
                dest -= 1;
                target.move(dest, cursor1);
                len1 -= 1;

                count1 += 1;
                count2 = 0;

                if (len1 == 0)
                    break :outer;
            } else {
                cursor2 -= 1;
                dest -= 1;
                target.move(dest, cursor2);
                len2 -= 1;

                count2 += 1;
                count1 = 0;

                if (len2 == 1)
                    break :outer;
            }

            lib.assert.assert(len1 == cursor1 - start);
            lib.assert.assert(len2 == cursor2 - buffer);

            if (minGallop <= count1 or minGallop <= count2) break;
        }

        std.debug.print("l1 {} l2 {} c1 {} c2 {} d {}\n", .{ len1, len2, cursor1, cursor2, dest });

        while (true) {
            // ギャロップ動作
            lib.assert.assert(len1 > 0);
            lib.assert.assert(len2 > 1);

            lib.assert.assert(len1 == cursor1 - start);
            lib.assert.assert(len2 == cursor2 - buffer);

            std.debug.print("start {} end {} hint {}\n", .{ start, start + len1, start + len1 - 1 });
            count1 = timSortGallopRight(target, cursor2 - 1, start, start + len1, start + len1 - 1) -% start;
            count1 = len1 -% count1;
            std.debug.print("cnt1 {}\n", .{count1});
            if (count1 != 0) {
                dest -= count1;
                cursor1 -= count1;
                len1 -= count1;
                target.copy(dest, cursor1, count1);
                if (len1 == 0)
                    break :outer;
            }

            lib.assert.assert(len1 == cursor1 - start);
            lib.assert.assert(len2 == cursor2 - buffer);

            cursor2 -= 1;
            dest -= 1;
            target.move(dest, cursor2);
            len2 -= 1;
            if (len2 == 1)
                break :outer;

            lib.assert.assert(len1 == cursor1 - start);
            lib.assert.assert(len2 == cursor2 - buffer);

            std.debug.print("start {} end {} hint {}\n", .{ buffer, buffer + len2, buffer + len2 - 1 });
            count2 = timSortGallopLeft(target, cursor1 - 1, buffer, buffer + len2, buffer + len2 - 1) -% buffer;
            std.debug.print("cnt2 {}\n", .{count1});
            count2 = len2 -% count2;
            if (count2 != 0) {
                dest -= count2;
                cursor2 -= count2;
                len2 -= count2;
                target.copy(dest, cursor2, count2);
                if (len2 <= 1) // len2 == 1 or len2 == 0
                    break :outer;
            }

            lib.assert.assert(len1 == cursor1 - start);
            lib.assert.assert(len2 == cursor2 - buffer);

            cursor1 -= 1;
            dest -= 1;
            target.move(dest, cursor1);
            len1 -= 1;
            if (len1 == 0)
                break :outer;

            lib.assert.assert(len1 == cursor1 - start);
            lib.assert.assert(len2 == cursor2 - buffer);

            minGallop -= 1;
            if (count1 < MIN_GALLOP and count2 < MIN_GALLOP) break;
        }

        std.debug.print("l1 {} l2 {} c1 {} c2 {} d {} g\n", .{ len1, len2, cursor1, cursor2, dest });

        if (minGallop < 0)
            minGallop = 0;
        minGallop += 2;
    } // outer

    lib.assert.assert(len1 == cursor1 - start);
    lib.assert.assert(len2 == cursor2 - buffer);

    mg.* = if (minGallop < 1) 1 else minGallop;

    // 最後に残ったものを詰める
    if (len2 == 1) {
        lib.assert.assert(len1 > 0);
        dest -= len1;
        cursor1 -= len1;
        target.copy(dest, cursor1, len1);
        // 右側の左端は左端に
        target.move(dest - 1, cursor2 - 1);
    } else {
        lib.assert.assert(len1 == 0);
        lib.assert.assert(len2 > 0);
        target.copy(dest - len2, buffer, len2);
    }
}

test timSortMergeHigh {
    const allocator = std.testing.allocator;
    var target = LoggedSortTarget.empty;
    defer target.deinit(allocator);

    try target.resize(allocator, 200);
    for (0..50) |i| target.slice[i].v = i + 50;
    for (50..100) |i| target.slice[i].v = i + 100;
    for (100..150) |i| target.slice[i].v = i - 100;
    for (150..200) |i| target.slice[i].v = i - 50;
    var min_gallop: usize = 7;
    try timSortMergeHigh(allocator, &target, 0, 100, 200, &min_gallop);
    try lib.testing.expect(target.isSorted()).is(true);
}

/// 範囲 R[i] と R[i+1] をマージする。
/// i は R.len-2 または R.len-3 。
fn timSortMergeAt(allocator: Allocator, target: *LoggedSortTarget, run_stack: *std.ArrayList(Run), i: usize) !void {
    lib.assert.assert(2 <= run_stack.items.len);
    lib.assert.assert(i == run_stack.items.len - 2 or i == run_stack.items.len - 3);

    // 値の取り出し
    const a = run_stack.items[i];
    const b = run_stack.items[i + 1];
    lib.assert.assert(a.start <= a.end and b.start <= b.end);
    lib.assert.assert(a.end == b.start);

    // ソート済み左右端を飛ばす
    const left = timSortGallopLeft(target, b.start, a.start, a.end, a.start);
    const right = timSortGallopRight(target, a.end - 1, b.start, b.end, b.end - 1);

    // マージ
    // var min_gallop = MIN_GALLOP;
    if (a.end - left < right - b.start) {
        // try timSortMergeLow(allocator, target, left, a.end, right, &min_gallop);
        try mergeSort1Merge(allocator, target, left, a.end, right);
    } else {
        // try timSortMergeHigh(allocator, target, left, a.end, right);
        try mergeSort1Merge(allocator, target, left, a.end, right);
    }

    // マージしたランを合わせる
    run_stack.items[i].end = b.end;
    if (i + 3 == run_stack.items.len) {
        run_stack.items[i + 1] = run_stack.pop() orelse unreachable;
    } else {
        _ = run_stack.pop();
    }
}

/// ランのスタックが不変条件を満たすまでマージする。
/// 1. B + C < A
/// 2. C < B
fn timSortMergeCollapse(allocator: Allocator, target: *LoggedSortTarget, run_stack: *std.ArrayList(Run)) !void {
    while (1 < run_stack.items.len) {
        const p = run_stack.items;
        var n = p.len - 2; // { ..., n-2, n-1, n, n+1 }
        if ((0 < n and p[n - 1].len() <= p[n].len() + p[n + 1].len()) or
            (1 < n and p[n - 2].len() <= p[n - 1].len() + p[n].len()))
        {
            if (p[n - 1].len() < p[n + 1].len()) n -= 1;
            try timSortMergeAt(allocator, target, run_stack, n);
        } else if (p[n].len() <= p[n + 1].len()) {
            try timSortMergeAt(allocator, target, run_stack, n);
        } else {
            break;
        }
    }
}

/// ランのスタックが1つになるまでマージする。
fn timSortMergeForceCollapse(allocator: Allocator, target: *LoggedSortTarget, run_stack: *std.ArrayList(Run)) !void {
    while (1 < run_stack.items.len) {
        const p = run_stack.items;
        var n = p.len - 2; // { ..., n-2, n-1, n, n+1 }
        if (0 < n and p[n - 1].len() < p[n + 1].len()) n -= 1;
        try timSortMergeAt(allocator, target, run_stack, n);
    }
}

/// ティムソート。
/// マージソートをもとに挿入ソートを使用して高速にする。
pub fn timSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    debug(@src(), "配列 {f}", .{target});
    if (target.length() < 2) return;

    // const min_run = timSortMinRun2(target.length());
    const min_run: usize = 2; // 終わったら直す

    var run_stack = std.ArrayList(Run).empty;
    defer run_stack.deinit(allocator);

    var last_pos: usize = 0;
    while (last_pos < target.length()) {
        const run = timSortRun(target, last_pos, min_run);
        try run_stack.append(allocator, run);

        try timSortMergeCollapse(allocator, target, &run_stack);

        last_pos = run.end;
    }

    try timSortMergeForceCollapse(allocator, target, &run_stack);
    debug(@src(), "配列 {f}", .{target});
}
