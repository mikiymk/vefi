const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

// ある程度ランダムな整数を生成する。
var rng: std.Random.Xoshiro256 = undefined;
var rg: ?std.Random = null;
/// at_least <= i < less_than
fn random(T: type, at_least: T, less_than: T) T {
    return (rg orelse b: {
        rng = std.Random.Xoshiro256.init(@bitCast(std.time.timestamp()));
        const new_rg = rng.random();
        rg = new_rg;
        break :b new_rg;
    })
        .intRangeLessThan(T, at_least, less_than);
}

/// 比較と入れ替えの回数をカウントする
pub const LoggedSortTarget = struct {
    const Type = usize;
    slice: []Type = &.{},
    /// 読み込み回数
    read_count: usize = 0,
    /// 書き込み回数
    write_count: usize = 0,
    /// 比較回数
    compare_count: usize = 0,

    fn deinit(self: *@This(), allocator: Allocator) void {
        allocator.free(self.slice);
    }

    pub fn length(self: @This()) usize {
        return self.slice.len;
    }

    /// S[i] < S[j] なら真を返す。
    pub fn lessThan(self: *@This(), i: usize, j: usize) bool {
        self.read_count += 2;
        self.compare_count += 1;
        return self.slice[i] < self.slice[j];
    }

    /// S[i] < b なら真を返す。
    pub fn lessThanIV(self: *@This(), i: usize, b: Type) bool {
        self.read_count += 1;
        self.compare_count += 1;
        return self.slice[i] < b;
    }

    /// a < S[j] なら真を返す。
    pub fn lessThanVI(self: *@This(), a: Type, j: usize) bool {
        self.read_count += 1;
        self.compare_count += 1;
        return a < self.slice[j];
    }

    pub fn get(self: *@This(), i: usize) Type {
        self.read_count += 1;
        return self.slice[i];
    }

    pub fn set(self: *@This(), i: usize, v: Type) void {
        self.write_count += 1;
        self.slice[i] = v;
    }

    /// 位置aに位置bの値を入れる。
    pub fn move(self: *@This(), a: usize, b: usize) void {
        self.read_count += 1;
        self.write_count += 1;

        self.slice[a] = self.slice[b];
    }

    /// 位置aと位置bの値を入れかえる。
    pub fn swap(self: *@This(), a: usize, b: usize) void {
        self.read_count += 2;
        self.write_count += 2;

        const tmp = self.slice[a];
        self.slice[a] = self.slice[b];
        self.slice[b] = tmp;
    }

    const ShuffleAlgorithm = enum {
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
        /// すべて同じ値にする。
        flat,

        fn name(self: @This()) []const u8 {
            return switch (self) {
                .shuffle => "shuffle",
                .ascend => "ascend",
                .descend => "descend",
                .nearly_ascend => "nearly ascend",
                .nearly_descend => "nearly descend",
                .flat => "flat",
            };
        }
    };

    fn resize(self: *@This(), allocator: Allocator, len: usize) Allocator.Error!void {
        self.slice = try allocator.realloc(self.slice, len);
    }

    /// リセット用
    fn reset(self: *@This(), shuffle_algorithm: ShuffleAlgorithm) void {
        self.read_count = 0;
        self.write_count = 0;
        self.compare_count = 0;

        if (self.slice.len == 0) return;

        switch (shuffle_algorithm) {
            .shuffle => {
                self.reset(.ascend);

                var i = self.slice.len - 1;
                while (0 < i) : (i -= 1) {
                    const j = random(usize, 0, i + 1);
                    const tmp = self.slice[i];
                    self.slice[i] = self.slice[j];
                    self.slice[j] = tmp;
                }
            },
            .ascend => {
                for (self.slice, 0..) |*v, i| v.* = i;
            },
            .descend => {
                for (self.slice, 0..) |*v, i| v.* = self.slice.len - i - 1;
            },
            .nearly_ascend, .nearly_descend => {
                self.reset(if (shuffle_algorithm == .nearly_ascend) .ascend else .descend);
                var i: usize = 1;
                while (i < self.slice.len) : (i += 2) {
                    const tmp = self.slice[i];
                    self.slice[i] = self.slice[i - 1];
                    self.slice[i - 1] = tmp;
                }
            },
            .flat => {
                for (self.slice) |*v| v.* = 1;
            },
        }
    }

    fn isSorted(self: @This()) bool {
        if (self.slice.len < 2) return true;
        for (self.slice[0 .. self.slice.len - 1], self.slice[1..]) |a, b| {
            if (a > b) return false;
        }
        return true;
    }
};

/// アロケーション回数などを記録する。
const LoggedAllocator = struct {
    child_allocator: Allocator,
    /// アロケーション回数
    alloc_count: usize = 0,
    current_allocated: usize = 0,
    /// 最大メモリ空間
    max_allocated: usize = 0,

    pub fn init(child_allocator: Allocator) @This() {
        return .{ .child_allocator = child_allocator };
    }

    /// カウントをリセットする。
    pub fn reset(self: *@This()) void {
        self.alloc_count = 0;
        self.current_allocated = 0;
        self.max_allocated = 0;
    }

    /// アロケーターを作成する。
    pub fn allocator(self: *LoggedAllocator) Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .resize = resize,
                .remap = remap,
                .free = free,
            },
        };
    }

    fn alloc(ctx: *anyopaque, n: usize, alignment: std.mem.Alignment, ra: usize) ?[*]u8 {
        const self: *@This() = @ptrCast(@alignCast(ctx));
        self.alloc_count += 1;
        self.current_allocated += n;
        self.max_allocated = @max(self.current_allocated, self.max_allocated);
        return self.child_allocator.vtable.alloc(self.child_allocator.ptr, n, alignment, ra);
    }

    fn resize(ctx: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ra: usize) bool {
        const self: *@This() = @ptrCast(@alignCast(ctx));
        const success = self.child_allocator.vtable.resize(self.child_allocator.ptr, buf, alignment, new_len, ra);

        if (success) {
            self.alloc_count += 1;
            self.current_allocated -= buf.len;
            self.current_allocated += new_len;
            self.max_allocated = @max(self.current_allocated, self.max_allocated);
        }
        return success;
    }

    fn remap(ctx: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ra: usize) ?[*]u8 {
        const self: *@This() = @ptrCast(@alignCast(ctx));

        const result = self.child_allocator.vtable.remap(self.child_allocator.ptr, buf, alignment, new_len, ra);
        if (result != null) {
            self.alloc_count += 1;
            self.current_allocated -= buf.len;
            self.current_allocated += new_len;
            self.max_allocated = @max(self.current_allocated, self.max_allocated);
        }
        return result;
    }

    fn free(ctx: *anyopaque, buf: []u8, alignment: std.mem.Alignment, ra: usize) void {
        const self: *@This() = @ptrCast(@alignCast(ctx));
        self.current_allocated -= buf.len;
        self.child_allocator.vtable.free(self.child_allocator.ptr, buf, alignment, ra);
    }
};

const SortFn = fn (allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void;
const SortAlgorithm = struct { []const u8, *const SortFn };
const sort_algorithms_1 = [_]SortAlgorithm{
    .{ "bubble sort 1", bubbleSort1 },
    .{ "bubble sort 2", bubbleSort2 },
    .{ "bubble sort 3", bubbleSort3 },
    .{ "shaker sort", shakerSort },
    .{ "comb sort", combSort },
    .{ "gnome sort", gnomeSort },
    .{ "selection sort", selectionSort },
    .{ "insertion sort", insertionSort },
    .{ "shell sort", shellSort },
    // .{ "tree sort", treeSort },
    // .{ "library sort", librarySort },
    .{ "merge sort", mergeSort },
    .{ "merge sort (in place/order search/reverse rotation)", mergeSortInPlace1 },
    .{ "merge sort (in place/binary search/reverse rotation)", mergeSortInPlace2 },
    .{ "merge sort (in place/binary search/juggling rotation)", mergeSortInPlace3 },
    .{ "quick sort (lomuto partition)", quickSort1 },
    .{ "quick sort (hoare partition)", quickSort2 },
    .{ "heap sort (williams)", heapSort1 },
    .{ "heap sort (floyd)", heapSort2 },
    .{ "heap sort (bottom up)", heapSort3 },
    .{ "smooth sort (array sizes)", smoothSort1 },
    .{ "smooth sort (bit sizes)", smoothSort2 },
    .{ "odd-even sort", oddEvenSort },
};

const sort_algorithms_2 = [_]SortAlgorithm{
    .{ "stooge sort", stoogeSort },
    .{ "slow sort", slowSort },
};

const sort_algorithms_3 = [_]SortAlgorithm{
    .{ "bogo sort", bogoSort },
    .{ "bozo sort", bozoSort },
};

fn testSortAlgorithm(target: *LoggedSortTarget, allocator: Allocator, func_name: []const u8, func: *const SortFn) Allocator.Error!void {
    const shuffle_algorithms = [_]LoggedSortTarget.ShuffleAlgorithm{
        .shuffle,
        .ascend,
        .descend,
        .nearly_ascend,
        .nearly_descend,
        .flat,
    };

    var logged_allocator = LoggedAllocator.init(allocator);
    for (shuffle_algorithms) |algorithm| {
        target.reset(algorithm);
        logged_allocator.reset();
        const la = logged_allocator.allocator();
        try func(la, target);

        std.debug.print("{s}, {s:<14}, size: {d:5}, read: {d:8}, write: {d:8}, compare: {d:8}, alloc: {d:8}, space: {d:8}, {s}\n", .{
            func_name,                    algorithm.name(),               target.slice.len,
            target.read_count,            target.write_count,             target.compare_count,
            logged_allocator.alloc_count, logged_allocator.max_allocated, if (target.isSorted()) "sorted" else "not sorted",
        });
    }
}

const test_compare_length: bool = true;
pub fn testSorts(allocator: Allocator) !void {
    var target = LoggedSortTarget{};
    defer target.deinit(allocator);

    for (sort_algorithms_1) |a| {
        const name, const func = a;

        // サイズ0で動作するかどうか
        try target.resize(allocator, 0);
        try func(allocator, &target);

        // 各長さで検証
        for (if (test_compare_length) [_]usize{ 0, 1, 10, 100, 1000, 10000 } else [_]usize{100}) |length| {
            try target.resize(allocator, length);
            try testSortAlgorithm(&target, allocator, name, func);
        }
    }

    for (sort_algorithms_2) |a| {
        const name, const func = a;

        // サイズ0で動作するかどうか
        try target.resize(allocator, 0);
        try func(allocator, &target);

        // 各長さで検証
        for (if (test_compare_length) [_]usize{ 0, 1, 10, 100 } else [_]usize{100}) |length| {
            try target.resize(allocator, length);
            try testSortAlgorithm(&target, allocator, name, func);
        }
    }

    for (sort_algorithms_3) |a| {
        const name, const func = a;

        // サイズ0で動作するかどうか
        try target.resize(allocator, 0);
        try func(allocator, &target);

        // 各長さで検証
        for (if (test_compare_length) [_]usize{ 0, 1, 2, 4, 8 } else [_]usize{8}) |length| {
            try target.resize(allocator, length);
            try testSortAlgorithm(&target, allocator, name, func);
        }
    }
}

test "sort test" {
    const allocator = std.testing.allocator;
    try testSorts(allocator);
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

    const buffer = try allocator.alloc(LoggedSortTarget.Type, end - start);
    defer allocator.free(buffer);
    var i: usize = 0;

    while (left < mid and right < end) {
        if (target.lessThan(right, left)) {
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
    for (0..buffer.len) |j| {
        target.set(start + j, buffer[j]);
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
        if (target.lessThanIV(j, pivot)) {
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
        while (target.lessThanIV(lo, pivot)) : (lo += 1) {}
        while (start < hi and target.lessThanVI(pivot, hi)) : (hi -= 1) {}

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

    debug("計算済みレオナルド数: {any}", .{smooth_leonardo_array[0..n]});
    return smooth_leonardo_array[0..n];
}

/// 1つの木 S[start] から S[end-1] の範囲を再構築する。
fn smoothSort1InsertTree(target: *LoggedSortTarget, la: []const usize, start: usize, tree_size: usize) void {
    debug("{any} 木を再構築 {} - {}", .{ target.slice, start, start + la[tree_size] });
    if (tree_size < 2) return;

    const parent_index = start + la[tree_size] - 1;
    const left_child_index = start + la[tree_size - 1] - 1;
    const right_child_index = start + la[tree_size] - 2;

    debug("{any} 木を再構築 親 {}(値:{}) 左{}(値:{}) 右 {}(値:{})", .{ target.slice, parent_index, target.slice[parent_index], left_child_index, target.slice[left_child_index], right_child_index, target.slice[right_child_index] });

    var swap_child_index = left_child_index;
    var swap_child_tree_size = tree_size - 1;
    if (target.lessThan(left_child_index, right_child_index)) {
        debug("{any} 木を再構築 左 < 右", .{target.slice});
        // 左の子 < 右の子なら右の子と交換する。
        swap_child_index = right_child_index;
        swap_child_tree_size = tree_size - 2;
    }

    if (target.lessThan(parent_index, swap_child_index)) {
        // 親 < 子なら交換する。
        target.swap(parent_index, swap_child_index);
        debug("{any} 木を再構築 親 < 子", .{target.slice});
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

fn smoothSort1ShouldSwapRoot(target: *LoggedSortTarget, la: []const usize, current_root: usize, prev_root: usize, tree_size: usize) bool {
    const should_swap = target.lessThan(current_root, prev_root);
    if (1 < tree_size) {
        // 現在の木に子があるなら、前のルート < 子の場合に交換しない。
        const current_left_child = current_root - la[tree_size - 2] - 1;
        const current_right_child = current_root - 1;
        debug("{any} 現在の子 左: {}(値:{}) 右: {}(値:{})", .{ target.slice, current_left_child, target.slice[current_left_child], current_right_child, target.slice[current_right_child] });
        return should_swap and
            target.lessThan(current_left_child, prev_root) and
            target.lessThan(current_right_child, prev_root);
    }

    return should_swap;
}

/// 森を再構築する。
fn smoothSort1Rebalance(target: *LoggedSortTarget, la: []const usize, tree_sizes: std.ArrayList(usize), heap_size: usize) void {
    debug("{any} {any} 森を再構築 0 - {}", .{ target.slice, tree_sizes.items, heap_size });
    var current_root = heap_size - 1;
    var tree_index = tree_sizes.items.len - 1;

    while (0 < tree_index) {
        debug("{any} {any} 現在のルート: {}(値:{})", .{ target.slice, tree_sizes.items, current_root, target.slice[current_root] });
        debug("{any} {any} インデックス: {}(サイズ:{})", .{ target.slice, tree_sizes.items, tree_index, tree_sizes.items[tree_index] });
        const tree_size = tree_sizes.items[tree_index];
        const prev_root = current_root - la[tree_size];
        debug("{any} {any} 前のルート: {}(値:{})", .{ target.slice, tree_sizes.items, prev_root, target.slice[prev_root] });

        if (!smoothSort1ShouldSwapRoot(target, la, current_root, prev_root, tree_size)) {
            // 交換しないなら終了。
            break;
        }

        // 前の木のルートが大きいなら、交換する。
        target.swap(prev_root, current_root);
        debug("{any} {any} 交換", .{ target.slice, tree_sizes.items });
        current_root = prev_root;
        tree_index -= 1;
    }

    debug("{any} {any} 木を再構築 {} - {}", .{ target.slice, tree_sizes.items, current_root + 1 - la[tree_sizes.items[tree_index]], current_root + 1 });
    // 一番前に来た場合は一番前の木を再構築する。
    smoothSort1InsertTree(target, la, current_root + 1 - la[tree_sizes.items[tree_index]], tree_sizes.items[tree_index]);
    debug("{any} {any} 木を再構築 終了", .{ target.slice, tree_sizes.items });
}

/// 複数の木のリスト S[0] から S[end] までの範囲を再構築する。
fn smoothSort1InsertForest(allocator: Allocator, target: *LoggedSortTarget, la: []const usize, tree_sizes: *std.ArrayList(usize), heap_size: usize) Allocator.Error!void {
    debug("{any} {any} サイズ + 1", .{ target.slice, tree_sizes.items });
    try smoothSort1GrowForest(allocator, tree_sizes);
    debug("{any} {any}", .{ target.slice, tree_sizes.items });

    smoothSort1Rebalance(target, la, tree_sizes.*, heap_size);
}

/// 最大の要素を取り出し、森を再構築する。
fn smoothSort1ShrinkForest(allocator: Allocator, target: *LoggedSortTarget, la: []const usize, tree_sizes: *std.ArrayList(usize), heap_size: usize) Allocator.Error!void {
    debug("{any} {any} サイズ - 1", .{ target.slice, tree_sizes.items });
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

pub fn smoothSort1(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    // if (target.length() < 2) return;
    const la = smoothSortLeonardo(target.length());
    var tree_sizes = std.ArrayList(usize).empty;
    defer tree_sizes.deinit(allocator);

    {
        for (1..target.length() + 1) |heap_size| {
            debug("{any} {any} ヒープ化: 0 - {}", .{ target.slice, tree_sizes.items, heap_size });
            try smoothSort1InsertForest(allocator, target, la, &tree_sizes, heap_size);
            debug("{any} {any}", .{ target.slice, tree_sizes.items });
        }
    }

    {
        var heap_size = target.length();
        while (heap_size > 1) : (heap_size -= 1) {
            debug("{any} {any} 取り出し: 0 - {}", .{ target.slice, tree_sizes.items, heap_size });
            try smoothSort1ShrinkForest(allocator, target, la, &tree_sizes, heap_size);
            debug("{any} {any}", .{ target.slice, tree_sizes.items });
        }
    }
}

/// 1つの木 S[start] から S[end-1] の範囲を再構築する。
fn smoothSort2InsertTree(target: *LoggedSortTarget, la: []const usize, start: usize, tree_size: usize) void {
    debug("{any} 木を再構築 {} - {}", .{ target.slice, start, start + la[tree_size] });
    if (tree_size < 2) return;

    const parent_index = start + la[tree_size] - 1;
    const left_child_index = start + la[tree_size - 1] - 1;
    const right_child_index = start + la[tree_size] - 2;

    debug("{any} 木を再構築 親 {}(値:{}) 左{}(値:{}) 右 {}(値:{})", .{ target.slice, parent_index, target.slice[parent_index], left_child_index, target.slice[left_child_index], right_child_index, target.slice[right_child_index] });

    var swap_child_index = left_child_index;
    var swap_child_tree_size = tree_size - 1;
    if (target.lessThan(left_child_index, right_child_index)) {
        debug("{any} 木を再構築 左 < 右", .{target.slice});
        // 左の子 < 右の子なら右の子と交換する。
        swap_child_index = right_child_index;
        swap_child_tree_size = tree_size - 2;
    }

    if (target.lessThan(parent_index, swap_child_index)) {
        // 親 < 子なら交換する。
        target.swap(parent_index, swap_child_index);
        debug("{any} 木を再構築 親 < 子", .{target.slice});
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
    debug("{any} ({b}, {}) 森を再構築 0 - {}", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.*, heap_size });
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

        debug("{any} ({b}, {}) 現在のルート: {}(値:{})", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.*, current_root, target.slice[current_root] });
        debug("{any} ({b}, {}) ベクトル: {} サイズ: {}", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.*, vec, tree_size });
        const prev_root = current_root - la[tree_size];
        debug("{any} ({b}, {}) 前のルート: {}(値:{})", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.*, prev_root, target.slice[prev_root] });

        if (!smoothSort1ShouldSwapRoot(target, la, current_root, prev_root, tree_size)) {
            // 交換しないなら終了。
            break;
        }

        // 前の木のルートが大きいなら、交換する。
        target.swap(prev_root, current_root);
        debug("{any} ({b}, {}) 交換", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.* });
        current_root = prev_root;
        vec >>= 1;
        tree_size += 1;
    }

    debug("{any} ({b}, {}) 木を再構築 {} - {}", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.*, current_root + 1 - la[tree_size], current_root + 1 });
    // 一番前に来た場合は一番前の木を再構築する。
    smoothSort2InsertTree(target, la, current_root + 1 - la[tree_size], tree_size);
    debug("{any} ({b}, {}) 木を再構築 終了", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.* });
}

/// 複数の木のリスト S[0] から S[end] までの範囲を再構築する。
fn smoothSort2InsertForest(target: *LoggedSortTarget, la: []const usize, tree_sizes_vec: *usize, tree_sizes_zero_pointer: *usize, heap_size: usize) void {
    debug("{any} ({b}, {}) サイズ + 1", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.* });
    smoothSort2GrowForest(tree_sizes_vec, tree_sizes_zero_pointer);
    debug("{any} ({b}, {}) ", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.* });

    smoothSort2Rebalance(target, la, tree_sizes_vec, tree_sizes_zero_pointer, heap_size);
}

/// 最大の要素を取り出し、森を再構築する。
fn smoothSort2ShrinkForest(target: *LoggedSortTarget, la: []const usize, tree_sizes_vec: *usize, tree_sizes_zero_pointer: *usize, heap_size: usize) void {
    debug("{any} ({b}, {}) サイズ - 1", .{ target.slice, tree_sizes_vec.*, tree_sizes_zero_pointer.* });
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

pub fn smoothSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    // if (target.length() < 2) return;
    const la = smoothSortLeonardo(target.length());

    var tree_sizes_vec: usize = 0;
    var tree_sizes_zero_pointer: usize = 0;

    {
        for (1..target.length() + 1) |heap_size| {
            debug("{any} ({b}, {}) ヒープ化: 0 - {}", .{ target.slice, tree_sizes_vec, tree_sizes_zero_pointer, heap_size });
            smoothSort2InsertForest(target, la, &tree_sizes_vec, &tree_sizes_zero_pointer, heap_size);
            debug("{any} ({b}, {})", .{ target.slice, tree_sizes_vec, tree_sizes_zero_pointer });
        }
    }

    {
        var heap_size = target.length();
        while (heap_size > 1) : (heap_size -= 1) {
            debug("{any} ({b}, {}) 取り出し: 0 - {}", .{ target.slice, tree_sizes_vec, tree_sizes_zero_pointer, heap_size });
            smoothSort2ShrinkForest(target, la, &tree_sizes_vec, &tree_sizes_zero_pointer, heap_size);
            debug("{any} ({b}, {})", .{ target.slice, tree_sizes_vec, tree_sizes_zero_pointer });
        }
    }
}

fn bogoSortShuffle(target: *LoggedSortTarget) void {
    var i = target.length() - 1;
    while (0 < i) : (i -= 1) {
        const j = random(usize, 0, i + 1);
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
        const i = random(usize, 0, target.length());
        const j = random(usize, 0, target.length());
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

// bucket sort
// tim sort
// intro sort
