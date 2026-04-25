const std = @import("std");
const Allocator = std.mem.Allocator;

var rand: ?std.Random = null;
/// at_least <= i <= at_most
fn random(T: type, at_least: T, at_most: T) T {
    if (rand == null) {
        var rng = std.Random.Xoshiro256.init(@bitCast(std.time.timestamp()));
        rand = rng.random();
    }

    return rand.?.intRangeAtMost(T, at_least, at_most);
}

/// 比較と入れ替えの回数をカウントする
pub const LoggedSortTarget = struct {
    const T = usize;
    slice: []T,
    /// 読み込み回数
    read_count: usize = 0,
    /// 書き込み回数
    write_count: usize = 0,
    /// 比較回数
    compare_count: usize = 0,
    /// アロケーション回数
    alloc_count: usize = 0,
    current_allocated: usize = 0,
    /// 最大メモリ空間
    max_allocated: usize = 0,

    pub fn length(self: @This()) usize {
        return self.slice.len;
    }

    /// 位置aの値 < 位置bの値なら真を返す。
    pub fn lessThan(self: *@This(), a: usize, b: usize) bool {
        self.read_count += 2;
        self.compare_count += 1;
        return self.slice[a] < self.slice[b];
    }

    /// 位置aの値 < b なら真を返す。
    pub fn lessThanIdxVal(self: *@This(), a: usize, b_value: T) bool {
        self.read_count += 1;
        self.compare_count += 1;
        return self.slice[a] < b_value;
    }

    /// a < 位置bの値 なら真を返す。
    pub fn lessThanValIdx(self: *@This(), a_value: T, b: usize) bool {
        self.read_count += 1;
        self.compare_count += 1;
        return a_value < self.slice[b];
    }

    /// 位置aと位置bの値を入れかえる。
    pub fn swap(self: *@This(), a: usize, b: usize) void {
        self.read_count += 2;
        self.write_count += 2;

        const tmp = self.slice[a];
        self.slice[a] = self.slice[b];
        self.slice[b] = tmp;
    }

    /// 位置aに位置bの値を入れる。
    pub fn move(self: *@This(), a: usize, b: usize) void {
        self.read_count += 1;
        self.write_count += 1;

        self.slice[a] = self.slice[b];
    }

    pub fn get(self: *@This(), i: usize) T {
        self.read_count += 1;
        return self.slice[i];
    }

    pub fn set(self: *@This(), i: usize, v: T) void {
        self.write_count += 1;
        self.slice[i] = v;
    }

    /// 配列を作成する。
    pub fn alloc(self: *@This(), allocator: Allocator, size: usize) Allocator.Error![]T {
        self.alloc_count += 1;
        self.current_allocated += size;
        if (self.max_allocated < self.current_allocated) {
            self.max_allocated = self.current_allocated;
        }

        return allocator.alloc(T, size);
    }

    /// 配列を解放する。
    pub fn free(self: *@This(), allocator: Allocator, slice: []T) void {
        self.current_allocated -= slice.len;
        allocator.free(slice);
    }

    /// 作成した配列に値を書き出す。
    pub fn readOut(self: *@This(), index: usize, slice: []T, slice_index: usize) void {
        self.read_count += 1;
        slice[slice_index] = self.slice[index];
    }

    /// 作成した配列から値を書き入れる。
    pub fn writeIn(self: *@This(), index: usize, slice: []T, slice_index: usize) void {
        self.write_count += 1;
        self.slice[index] = slice[slice_index];
    }

    pub const ShuffleAlgorithm = enum {
        /// すべてランダムに並びかえる。
        shuffle,
        /// 昇順にソートする。
        ascend,
        /// 降順にソートする。
        descend,
        /// ほぼ昇順にソートする。 すべての値がソート済み位置±1にある。
        nearly_ascend,
        /// ほぼ降順にソートする。 すべての値がソート済み位置±1にある。
        nearly_descend,
    };

    /// リセット用
    pub fn reset(self: *@This(), shuffle_algorithm: ShuffleAlgorithm) void {
        self.read_count = 0;
        self.write_count = 0;
        self.compare_count = 0;
        self.alloc_count = 0;
        self.current_allocated = 0;
        self.max_allocated = 0;

        switch (shuffle_algorithm) {
            .shuffle => {
                self.reset(.ascend);

                var i = self.slice.len - 1;
                while (0 < i) : (i -= 1) {
                    const j = random(usize, 0, i);
                    const tmp = self.slice[i];
                    self.slice[i] = self.slice[j];
                    self.slice[j] = tmp;
                }
            },
            .ascend => {
                for (self.slice, 0..) |*v, i| {
                    v.* = i;
                }
            },
            .descend => {
                for (self.slice, 0..) |*v, i| {
                    v.* = self.slice.len - i - 1;
                }
            },
            .nearly_ascend, .nearly_descend => {
                if (shuffle_algorithm == .nearly_ascend) {
                    self.reset(.ascend);
                } else {
                    self.reset(.descend);
                }

                var i: usize = 1;
                while (i < self.slice.len) : (i += 2) {
                    const tmp = self.slice[i];
                    self.slice[i] = self.slice[i - 1];
                    self.slice[i - 1] = tmp;
                }
            },
        }
    }

    pub fn isSorted(self: @This()) bool {
        if (self.slice.len < 2) return true;
        for (self.slice[0 .. self.slice.len - 1], self.slice[1..]) |a, b| {
            if (a > b) return false;
        }
        return true;
    }

    pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("size: {d:5} read: {d:8} write: {d:8} compare: {d:8} alloc: {d:8} space: {d:8} {s}", .{
            self.slice.len,
            self.read_count,
            self.write_count,
            self.compare_count,
            self.alloc_count,
            self.max_allocated,
            if (self.isSorted()) "sorted" else "not sorted",
        });
    }
};

const SortFn = fn (allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void;
fn testSortAlgorithm(target: *LoggedSortTarget, allocator: Allocator, func: *const SortFn) Allocator.Error!void {
    target.reset(.shuffle);
    try func(allocator, target);
    std.debug.print("shuffle        {f}\n", .{target});

    target.reset(.ascend);
    try func(allocator, target);
    std.debug.print("ascend         {f}\n", .{target});

    target.reset(.descend);
    try func(allocator, target);
    std.debug.print("descend        {f}\n", .{target});

    target.reset(.nearly_ascend);
    try func(allocator, target);
    std.debug.print("nearly ascend  {f}\n", .{target});

    target.reset(.nearly_descend);
    try func(allocator, target);
    std.debug.print("nearly descend {f}\n", .{target});

    var empty_target = LoggedSortTarget{ .slice = &.{} };
    try func(allocator, &empty_target);
}

test "sort test" {
    const allocator = std.testing.allocator;
    const array_length = 100;
    var array: [array_length]usize = undefined;
    var target = LoggedSortTarget{ .slice = array[0..array_length] };

    std.debug.print("bubble sort 1\n", .{});
    try testSortAlgorithm(&target, allocator, bubbleSort1);
    std.debug.print("bubble sort 2\n", .{});
    try testSortAlgorithm(&target, allocator, bubbleSort2);
    std.debug.print("bubble sort 3\n", .{});
    try testSortAlgorithm(&target, allocator, bubbleSort3);
    std.debug.print("shaker sort\n", .{});
    try testSortAlgorithm(&target, allocator, shakerSort);
    std.debug.print("comb sort\n", .{});
    try testSortAlgorithm(&target, allocator, combSort);
    std.debug.print("gnome sort\n", .{});
    try testSortAlgorithm(&target, allocator, gnomeSort);
    std.debug.print("selection sort\n", .{});
    try testSortAlgorithm(&target, allocator, selectionSort);
    std.debug.print("insertion sort\n", .{});
    try testSortAlgorithm(&target, allocator, insertionSort);
    std.debug.print("shell sort\n", .{});
    try testSortAlgorithm(&target, allocator, shellSort);
    // std.debug.print("tree sort\n", .{});
    // try testSortAlgorithm(target,allocator, treeSort);
    // std.debug.print("library sort\n", .{});
    // try testSortAlgorithm(target,allocator, librarySort);
    std.debug.print("merge sort\n", .{});
    try testSortAlgorithm(&target, allocator, mergeSort);
    std.debug.print("merge sort (in place/order search/reverse rotation)\n", .{});
    try testSortAlgorithm(&target, allocator, mergeSortInPlace1);
    std.debug.print("merge sort (in place/binary search/reverse rotation)\n", .{});
    try testSortAlgorithm(&target, allocator, mergeSortInPlace2);
    std.debug.print("merge sort (in place/binary search/juggling rotation)\n", .{});
    try testSortAlgorithm(&target, allocator, mergeSortInPlace3);
    std.debug.print("quick sort (lomuto partition)\n", .{});
    try testSortAlgorithm(&target, allocator, quickSort1);
    std.debug.print("quick sort (hoare partition)\n", .{});
    try testSortAlgorithm(&target, allocator, quickSort2);
    std.debug.print("heap sort (williams)\n", .{});
    try testSortAlgorithm(&target, allocator, heapSort1);
    std.debug.print("heap sort (floyd)\n", .{});
    try testSortAlgorithm(&target, allocator, heapSort2);
    std.debug.print("heap sort (bottom up)\n", .{});
    try testSortAlgorithm(&target, allocator, heapSort3);
    std.debug.print("stooge sort\n", .{});
    try testSortAlgorithm(&target, allocator, stoogeSort);
    std.debug.print("slow sort\n", .{});
    try testSortAlgorithm(&target, allocator, slowSort);
    std.debug.print("odd-even sort\n", .{});
    try testSortAlgorithm(&target, allocator, oddEvenSort);
}

test "slow sort test" {
    const allocator = std.testing.allocator;
    const array_length = 8;
    var array: [array_length]usize = undefined;
    var target = LoggedSortTarget{ .slice = array[0..array_length] };

    std.debug.print("bogo sort\n", .{});
    try testSortAlgorithm(&target, allocator, bogoSort);
    std.debug.print("bozo sort\n", .{});
    try testSortAlgorithm(&target, allocator, bozoSort);
}

/// バブルソート。
/// すべての要素について、隣と比較して逆順なら入れ替える。
/// 要素数-1回繰り返す。
pub fn bubbleSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |_| {
        for (1..target.length()) |i| {
            if (target.lessThan(i, i - 1)) target.swap(i, i - 1);
        }
    }
}

/// バブルソート。
/// ソート済みが確定しているところは比較を行わない。
pub fn bubbleSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        for (1..target.length() - i) |j| {
            if (target.lessThan(j, j - 1)) {
                target.swap(j, j - 1);
            }
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
            if (target.lessThan(i, i - 1)) {
                target.swap(i, i - 1);
                last_swap_index = i;
            }
        }
        len = last_swap_index;
    }
}

/// シェイカーソート。
/// 前から後ろ、後ろから前を交互に繰り返す。
pub fn shakerSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;

    var top_index: usize = 0;
    var bottom_index = target.length() - 1;

    while (true) {
        // 順方向
        var last_swap_index = top_index;

        for (top_index..bottom_index) |i| {
            if (target.lessThan(i + 1, i)) {
                target.swap(i + 1, i);
                last_swap_index = i;
            }
        }
        bottom_index = last_swap_index;

        if (top_index == bottom_index) {
            break;
        }

        // 逆方向
        last_swap_index = bottom_index;

        var i = bottom_index;
        while (i > top_index) : (i -= 1) {
            if (target.lessThan(i, i - 1)) {
                target.swap(i, i - 1);
                last_swap_index = i;
            }
        }
        top_index = last_swap_index;

        if (top_index == bottom_index) {
            break;
        }
    }
}

/// 整数を1.3で割った整数を計算する。
fn combSortDivBy13(num: usize) usize {
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
                if (target.lessThan(i, i - gap)) {
                    target.swap(i, i - gap);
                    last_swap_index = i;
                }
            }
            len = last_swap_index;
        }

        if (gap < 2) break;
    }
}

/// ノームソート。
/// 位置を移動して前後の順序を並べる。
pub fn gnomeSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var i: usize = 1;
    while (i < target.length()) {
        if (target.lessThan(i, i - 1)) {
            target.swap(i, i - 1);
            if (i == 1) {
                i += 1;
            } else {
                i -= 1;
            }
        } else {
            i += 1;
        }
    }
}

/// 選択ソート。
/// 最小の値を選択して先頭から配置する。
pub fn selectionSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        var min_index: usize = i;
        for (i..target.length()) |j| {
            if (target.lessThan(j, min_index)) {
                min_index = j;
            }
        }

        if (i != min_index) {
            target.swap(i, min_index);
        }
    }
}

/// 挿入ソート。
/// 最小の値を選択して先頭から配置する。
pub fn insertionSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        var j = i;
        while (0 < j and target.lessThan(j, j - 1)) : (j -= 1) {
            target.swap(j, j - 1);
        }
    }
}

/// シェルソートの間隔を決める関数。
/// 案1. 2で割る (切り捨て)
fn shellSortGap1(num: usize) usize {
    return num / 2;
}
/// シェルソートの間隔を決める関数。
/// 案2. 3で割る (切り捨て)
fn shellSortGap2(num: usize) usize {
    return num / 3;
}
/// シェルソートの間隔を決める関数。
/// 案3. a(0)=1; a(k) = 4^k+3*2^(k-1)+1
fn shellSortGap3(num: usize) usize {
    const pow = std.math.powi;
    if (num <= 8) return 1;
    var k: usize = 2;
    var last_a_k: usize = 8;
    while (true) {
        const pow_4 = pow(usize, 4, k) catch unreachable;
        const pow_2 = pow(usize, 2, k - 1) catch unreachable;
        const a_k = pow_4 + 3 * pow_2 + 1;
        if (num <= a_k) return last_a_k;
        k += 1;
        last_a_k = a_k;
    }
}

/// シェルソート。
/// 間隔を空けて挿入ソートをする。
pub fn shellSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var gap = target.length();
    while (true) {
        gap = shellSortGap3(gap);
        for (0..target.length()) |i| {
            var j = i;
            while (gap <= j and target.lessThan(j, j - gap)) : (j -= gap) {
                target.swap(j, j - gap);
            }
        }

        if (gap < 2) break;
    }
}

/// ツリーソート。
/// 二分探索木を使用してソートする。
pub fn treeSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    // 木構造を使う
    _ = allocator;
    _ = target;
}

/// 図書館ソート。
/// 隙間を空けて挿入ソートする。
pub fn librarySort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    // 難しそう
    _ = allocator;
    _ = target;
}

fn mergeSortMerge(allocator: Allocator, target: *LoggedSortTarget, start: usize, mid: usize, end: usize) Allocator.Error!void {
    var left = start;
    var right = mid;

    const buffer = try target.alloc(allocator, end - start);
    defer target.free(allocator, buffer);
    var i: usize = 0;

    while (left < mid and right < end) {
        if (target.lessThan(right, left)) {
            target.readOut(right, buffer, i);
            right += 1;
        } else {
            target.readOut(left, buffer, i);
            left += 1;
        }
        i += 1;
    }

    // 残りを入れる
    while (left < mid) {
        target.readOut(left, buffer, i);
        left += 1;
        i += 1;
    }
    while (right < end) {
        target.readOut(right, buffer, i);
        right += 1;
        i += 1;
    }

    // 戻す
    for (0..buffer.len) |j| {
        target.writeIn(start + j, buffer, j);
    }
}

/// 分割されたマージソート。
fn mergeSortRange(allocator: Allocator, target: *LoggedSortTarget, start: usize, end: usize) Allocator.Error!void {
    if (end - start <= 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    try mergeSortRange(allocator, target, start, mid);
    try mergeSortRange(allocator, target, mid, end);
    // ソートした2つをマージする。
    try mergeSortMerge(allocator, target, start, mid, end);
}

/// マージソート。
/// 分割して結合を繰り返す。
pub fn mergeSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    try mergeSortRange(allocator, target, 0, target.length());
}

/// S[l+i] > S[r] になる最小のl+iを見つける。
/// 見つからなければrを返す。
/// 順番に探す。
fn mergeSortInPlace1SearchLeft(target: *LoggedSortTarget, start: usize, end: usize) usize {
    var i: usize = 0;
    while (start + i < end and !target.lessThan(end, start + i)) : (i += 1) {}
    return i;
}

/// S[l] <= S[r+i] になる最小のr+iを見つける。
/// 見つからなければendを返す。
fn mergeSortInPlace1SearchRight(target: *LoggedSortTarget, left: usize, right: usize, end: usize) usize {
    var i: usize = 0;
    while (right + i < end and target.lessThan(right + i, left)) : (i += 1) {}
    return i;
}

/// 要素を逆順にする。
fn mergeSortInPlace1Reverse(target: *LoggedSortTarget, left: usize, right: usize) void {
    const size = right - left;
    const mid = size / 2;
    for (0..mid) |i| {
        target.swap(left + i, right - i - 1);
    }
}

/// 範囲内をn個だけ右方向にずらす。
fn mergeSortInPlace1RotateRight(target: *LoggedSortTarget, left: usize, right: usize, n: usize) void {
    mergeSortInPlace1Reverse(target, left, right);
    mergeSortInPlace1Reverse(target, left + n, right);
    mergeSortInPlace1Reverse(target, left, left + n);
}

/// 分割されたIn-Placeマージソート。
fn mergeSortInPlace1Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end - start <= 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    mergeSortInPlace1Internal(target, start, mid);
    mergeSortInPlace1Internal(target, mid, end);

    // ソートした2つをマージする。
    var left = start;
    var right = mid;
    while (true) {
        // 1. 左を進める
        left += mergeSortInPlace1SearchLeft(target, left, right);
        // 2. 左が終わりなら終了
        if (left == right) break;
        // 3. 右を進める
        const n = mergeSortInPlace1SearchRight(target, left, right, end);
        right += n;
        // 4. 右回転
        mergeSortInPlace1RotateRight(target, left, right, n);
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += n;
    }
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn mergeSortInPlace1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    mergeSortInPlace1Internal(target, 0, target.length());
}

/// S[l+i] > S[r] になる最小のl+iを見つける。
/// 見つからなければrを返す。
/// 二分探索を使う。
fn mergeSortInPlace2SearchLeft(target: *LoggedSortTarget, start: usize, end: usize) usize {
    var a = start;
    var b = end;
    while (a < b) {
        const m = (a + b) / 2;
        if (target.lessThan(end, m)) {
            b = m;
        } else {
            a = m + 1;
        }
    }

    return a - start;
}

/// S[l] <= S[r+i] になる最小のr+iを見つける。
/// 見つからなければendを返す。
/// 二分探索を使う。
fn mergeSortInPlace2SearchRight(target: *LoggedSortTarget, left: usize, right: usize, end: usize) usize {
    var a = right;
    var b = end;
    while (a < b) {
        const m = (a + b) / 2;
        // !(m < left) == (left <= m)
        if (!target.lessThan(m, left)) {
            b = m;
        } else {
            a = m + 1;
        }
    }

    return a - right;
}

/// 分割されたIn-Placeマージソート。
fn mergeSortInPlace2Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end - start <= 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    mergeSortInPlace2Internal(target, start, mid);
    mergeSortInPlace2Internal(target, mid, end);

    // ソートした2つをマージする。
    var left = start;
    var right = mid;
    while (true) {
        // 1. 左を進める
        left += mergeSortInPlace2SearchLeft(target, left, right);
        // 2. 左が終わりなら終了
        if (left == right) break;
        // 3. 右を進める
        const n = mergeSortInPlace2SearchRight(target, left, right, end);
        right += n;
        // 4. 右回転
        mergeSortInPlace1RotateRight(target, left, right, n); // 1と同じものを使う
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += n;
    }
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn mergeSortInPlace2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    mergeSortInPlace2Internal(target, 0, target.length());
}

/// 最大公約数を求める。
/// 必ず a < b にする。
fn mergeSortInPlace3Gcd(a: usize, b: usize) usize {
    return if (a == 0) b else mergeSortInPlace3Gcd(b % a, a);
}

/// 範囲内をn個だけ右方向にずらす。
/// 反転を使わない。
fn mergeSortInPlace3RotateRight(target: *LoggedSortTarget, left: usize, right: usize, size: usize) void {
    const length = right - left;
    const move_left_size = length - size;
    const cycle_count = mergeSortInPlace3Gcd(move_left_size, length);

    for (0..cycle_count) |i| {
        const tmp = target.get(left + i);
        var current_index = i;
        var next_index: usize = undefined;
        while (current_index < length) {
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
    if (end - start <= 1) return;
    const mid = (start + end) / 2;
    // 部分についてソートする。
    mergeSortInPlace3Internal(target, start, mid);
    mergeSortInPlace3Internal(target, mid, end);

    // ソートした2つをマージする。
    var left = start;
    var right = mid;
    while (true) {
        // 1. 左を進める
        left += mergeSortInPlace2SearchLeft(target, left, right);
        // 2. 左が終わりなら終了
        if (left == right) break;
        // 3. 右を進める
        const n = mergeSortInPlace2SearchRight(target, left, right, end);
        right += n;
        // 4. 右回転
        mergeSortInPlace3RotateRight(target, left, right, n); // 1と同じものを使う
        // 5. 右が終わりなら終了
        if (right == end) break;
        // 6. 右からの分だけ左を進める
        left += n;
    }
}

/// In-Placeなマージソート。
/// 分割して結合を繰り返す。追加のメモリを必要としない。
pub fn mergeSortInPlace3(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
    mergeSortInPlace3Internal(target, 0, target.length());
}

/// クイックソートで小さい値を前、大きい値を後ろに移動し、ピボット位置を返す。
/// Lomuto法。
fn quickSort1Partition(target: *LoggedSortTarget, start: usize, end: usize) usize {
    // 最後の要素をピボットにする
    const pivot = target.get(end - 1);

    var i = start;
    for (start..end - 1) |j| {
        if (target.lessThanIdxVal(j, pivot)) {
            target.swap(i, j);
            i += 1;
        }
    }
    target.swap(i, end - 1);
    return i;
}

/// 分割されたクイックソート。
/// startは含む、endは含まない。
fn quickSort1Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    // 要素が2未満(0または1)の場合
    if (end - start < 2) return;

    const partition = quickSort1Partition(target, start, end);
    quickSort1Internal(target, start, partition);
    quickSort1Internal(target, partition + 1, end);
}

/// クイックソート。
/// ある値より大きい値と小さい値に分類するのを繰り返す。
pub fn quickSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    quickSort1Internal(target, 0, target.length());
}

/// クイックソートで小さい値を前、大きい値を後ろに移動し、ピボット位置を返す。
/// Hoare法。
fn quickSort2Partition(target: *LoggedSortTarget, start: usize, end: usize) usize {
    var lo: usize = start;
    var hi: usize = end - 1;
    const pivot = target.get((start + end) / 2);
    while (true) {
        while (target.lessThanIdxVal(lo, pivot)) : (lo += 1) {}
        while (start < hi and target.lessThanValIdx(pivot, hi)) : (hi -= 1) {}

        if (lo >= hi) {
            return hi;
        }

        target.swap(lo, hi);
        lo += 1;
        hi -= 1;
    }
}

/// 分割されたクイックソート。
/// startは含む、endは含まない。
fn quickSort2Internal(target: *LoggedSortTarget, start: usize, end: usize) void {
    // 要素数が0または1の場合
    if (end <= start + 1) return;

    const partition = quickSort2Partition(target, start, end);
    if (partition + 1 != end)
        quickSort2Internal(target, start, partition + 1);
    quickSort2Internal(target, partition + 1, end);
}

/// クイックソート。
/// ある値より大きい値と小さい値に分類するのを繰り返す。
pub fn quickSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    quickSort2Internal(target, 0, target.length());
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
fn heapSortShiftUp(target: *LoggedSortTarget, index: usize) void {
    var node = index;
    while (node > 0) {
        const parent = heapSortParent(node);
        if (target.lessThan(parent, node)) { // 親と比較して逆順なら入れ替える。
            target.swap(parent, node);
            node = parent;
        } else { // 正順なら終了。
            break;
        }
    }
}

/// ルートをiとするヒープを作成する。
/// Left(i)とRight(i)はヒープ。
fn heapSortShiftDown(target: *LoggedSortTarget, index: usize, heap_size: usize) void {
    var current_index = index;
    while (true) {
        var max = current_index;
        const left_child = heapSortLeftChild(current_index);
        const right_child = heapSortRightChild(current_index);

        if (left_child < heap_size and target.lessThan(max, left_child)) {
            max = left_child;
        }
        if (right_child < heap_size and target.lessThan(max, right_child)) {
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
        heapSortShiftUp(target, i);
    }

    i -= 1;
    while (i > 0) : (i -= 1) {
        target.swap(0, i);
        heapSortShiftDown(target, 0, i);
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
            heapSort3ShiftDown(target, start, target.length());
        }
    }

    {
        var end = target.length() - 1;
        while (0 < end) : (end -= 1) {
            target.swap(0, end);
            heapSortShiftDown(target, 0, end);
        }
    }
}

fn heapSort3LeafSearch(target: *LoggedSortTarget, index: usize, heap_size: usize) usize {
    var j = index;
    while (heapSortRightChild(j) < heap_size) {
        const left = heapSortLeftChild(j);
        const right = heapSortRightChild(j);
        j = if (target.lessThan(left, right)) right else left;
    }
    if (heapSortLeftChild(j) < heap_size) {
        j = heapSortLeftChild(j);
    }
    return j;
}

fn heapSort3ShiftDown(target: *LoggedSortTarget, index: usize, heap_size: usize) void {
    var j = heapSort3LeafSearch(target, index, heap_size);
    while (target.lessThan(j, index)) {
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

fn bogoSortShuffle(target: *LoggedSortTarget) void {
    var i = target.length() - 1;
    while (0 < i) : (i -= 1) {
        const j = random(usize, 0, i);
        target.swap(i, j);
    }
}

fn bogoSortSorted(target: *LoggedSortTarget) bool {
    if (target.length() < 2) return true;
    for (0..target.length() - 1) |i| {
        if (target.lessThan(i + 1, i)) return false;
    }
    return true;
}

pub fn bogoSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    while (true) {
        bogoSortShuffle(target);
        if (bogoSortSorted(target)) break;
    }
}

pub fn bozoSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    while (true) {
        const i = random(usize, 0, target.length() - 1);
        const j = random(usize, 0, target.length() - 1);
        target.swap(i, j);
        if (bogoSortSorted(target)) break;
    }
}

fn stoogeSortInternal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (target.lessThan(end - 1, start)) {
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

pub fn stoogeSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    stoogeSortInternal(target, 0, target.length());
}

fn slowSortInternal(target: *LoggedSortTarget, start: usize, end: usize) void {
    if (end < start + 2) return;
    const mid = (start + end - 1) / 2;
    slowSortInternal(target, start, mid + 1);
    slowSortInternal(target, mid + 1, end);
    if (target.lessThan(end - 1, mid)) {
        target.swap(end - 1, mid);
    }
    slowSortInternal(target, start, end - 1);
}

pub fn slowSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    slowSortInternal(target, 0, target.length());
}

pub fn oddEvenSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var swapped = true;
    while (swapped) {
        swapped = false;
        {
            var i: usize = 1;
            while (i < target.length()) : (i += 2) {
                if (target.lessThan(i, i - 1)) {
                    target.swap(i, i - 1);
                    swapped = true;
                }
            }
        }
        {
            var i: usize = 2;
            while (i < target.length()) : (i += 2) {
                if (target.lessThan(i, i - 1)) {
                    target.swap(i, i - 1);
                    swapped = true;
                }
            }
        }
    }
}
