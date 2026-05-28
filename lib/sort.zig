const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

// ある程度ランダムな整数を生成する。
const RNG = std.Random.Xoshiro256;
var rng: ?RNG = null;
/// at_least <= i < less_than
fn random(T: type, at_least: T, less_than: T) T {
    if (rng == null) {
        rng = RNG.init(@intCast(std.time.timestamp()));
    }

    return rng.?.random().intRangeLessThan(T, at_least, less_than);
}

/// 比較と入れ替えの回数をカウントする
pub const LoggedSortTarget = struct {
    const Type = struct { v: usize, i: usize };
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

    pub fn get(self: *@This(), i: usize) Type {
        self.read_count += 1;
        return self.slice[i];
    }

    pub fn set(self: *@This(), i: usize, v: Type) void {
        self.write_count += 1;
        self.slice[i] = v;
    }

    /// a < b なら真を返す。
    pub fn compare(self: *@This(), a: Type, b: Type) bool {
        self.compare_count += 1;
        return a.v < b.v;
    }

    /// S[i] < S[j] なら真を返す。
    pub fn lessThan(self: *@This(), i: usize, j: usize) bool {
        return self.compare(self.get(i), self.get(j));
    }

    /// S[i] < b なら真を返す。
    pub fn lessThanIV(self: *@This(), i: usize, b: Type) bool {
        return self.compare(self.get(i), b);
    }

    /// a < S[j] なら真を返す。
    pub fn lessThanVI(self: *@This(), a: Type, j: usize) bool {
        return self.compare(a, self.get(j));
    }

    /// 位置iに位置jの値を入れる。
    pub fn move(self: *@This(), i: usize, j: usize) void {
        self.set(i, self.get(j));
    }

    /// 位置iと位置jの値を入れかえる。
    pub fn swap(self: *@This(), i: usize, j: usize) void {
        const tmp = self.get(i);
        self.set(i, self.get(j));
        self.set(j, tmp);
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
        /// それぞれ2つずつの値の昇順にする。
        double_ascend,
        /// それぞれ2つずつの値の降順にする。
        double_descend,

        fn name(self: @This()) []const u8 {
            return switch (self) {
                .shuffle => "shuffle",
                .ascend => "ascend",
                .descend => "descend",
                .nearly_ascend => "nearly ascend",
                .nearly_descend => "nearly descend",
                .flat => "flat",
                .double_ascend => "double ascend",
                .double_descend => "double descend",
            };
        }
    };

    /// 対象配列のサイズを変更する。
    /// リサイズ後はリセット推奨。
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
                for (self.slice, 0..) |*v, i| v.v = i;
            },
            .descend => {
                for (self.slice, 0..) |*v, i| v.v = self.slice.len - i - 1;
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
                for (self.slice) |*v| v.v = 1;
            },
            .double_ascend => {
                for (self.slice, 0..) |*v, i| v.v = i / 2;
            },
            .double_descend => {
                for (self.slice, 0..) |*v, i| v.v = (self.slice.len - i - 1) / 2;
            },
        }
        for (self.slice, 0..) |*v, i| v.i = i;
    }

    /// ソート済みか判定する。
    fn isSorted(self: @This()) bool {
        if (self.slice.len < 2) return true;
        for (self.slice[0 .. self.slice.len - 1], self.slice[1..]) |a, b| {
            if (a.v > b.v) return false;
        }
        return true;
    }

    /// ソート済みかつ安定ソートされているか判定する。
    fn isStableSorted(self: @This()) bool {
        if (self.slice.len < 2) return true;
        for (self.slice[0 .. self.slice.len - 1], self.slice[1..]) |a, b| {
            if (a.v > b.v or (a.v == b.v and a.i > b.i)) return false;
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
    pub fn allocator(self: *@This()) Allocator {
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
        const result = self.child_allocator.vtable.alloc(self.child_allocator.ptr, n, alignment, ra);
        if (result != null) {
            self.alloc_count += 1;
            self.current_allocated += n;
            self.max_allocated = @max(self.current_allocated, self.max_allocated);
        }
        return result;
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

pub fn sortLogging(allocator: Allocator) !void {
    var target = LoggedSortTarget{};
    defer target.deinit(allocator);
    try target.resize(allocator, 1000);

    for (0..100) |_| {
        target.reset(.shuffle);
        std.debug.print("ソート開始 {any}\n", .{target.slice});
        try timSort(allocator, &target);
        std.debug.print("ソート終了 {any} ", .{target.slice});
        if (target.isSorted()) {
            std.debug.print("ソート成功\n", .{});
        } else {
            std.debug.print("ソート失敗\n", .{});
            return;
        }
    }
}

const SortAlgorithm = struct { []const u8, *const SortFn };
const sort_algorithms_1 = [_]SortAlgorithm{
    .{ "bubble sort 1", bubbleSort1 },
    .{ "bubble sort 2", bubbleSort2 },
    .{ "bubble sort 3", bubbleSort3 },
    .{ "shaker sort", shakerSort },
    .{ "comb sort", combSort },
    .{ "gnome sort", gnomeSort },
    .{ "selection sort", selectionSort },
    .{ "insertion sort (swap)", insertionSort1 },
    .{ "insertion sort (move)", insertionSort2 },
    .{ "insertion sort (binary search)", binaryInsertionSort },
    .{ "shell sort (n/2^k)", shellSort1 },
    .{ "shell sort ((3^k-1)/2)", shellSort2 },
    .{ "shell sort (4^k+3*2^(k-1)+1)", shellSort3 },
    .{ "tree sort", treeSort },
    // .{ "library sort", librarySort },
    .{ "merge sort", mergeSort },
    .{ "merge sort (in place) 1", mergeSortInPlace1 },
    .{ "merge sort (in place) 2", mergeSortInPlace2 },
    .{ "merge sort (in place) 3", mergeSortInPlace3 },
    .{ "quick sort (lomuto partition)", quickSort1 },
    .{ "quick sort (hoare partition)", quickSort2 },
    .{ "heap sort (williams)", heapSort1 },
    .{ "heap sort (floyd)", heapSort2 },
    .{ "heap sort (bottom up)", heapSort3 },
    .{ "smooth sort (array sizes)", smoothSort1 },
    .{ "smooth sort (bit sizes)", smoothSort2 },
    .{ "odd-even sort", oddEvenSort },
    .{ "intro sort", introSort },
    .{ "tim sort", timSort },
};

const sort_algorithms_2 = [_]SortAlgorithm{
    .{ "stooge sort", stoogeSort },
    .{ "slow sort", slowSort },
};

const sort_algorithms_3 = [_]SortAlgorithm{
    .{ "bogo sort", bogoSort },
    .{ "bozo sort", bozoSort },
};

fn testSortAlgorithm(target: *LoggedSortTarget, allocator: Allocator, func_name: []const u8, func: *const SortFn) Allocator.Error!bool {
    var sort_succeed = true;
    const shuffle_algorithms = [_]LoggedSortTarget.ShuffleAlgorithm{
        .shuffle,
        .ascend,
        .descend,
        .nearly_ascend,
        .nearly_descend,
        .flat,
        .double_ascend,
        .double_descend,
    };

    var logged_allocator = LoggedAllocator.init(allocator);
    for (shuffle_algorithms) |algorithm| {
        target.reset(algorithm);
        logged_allocator.reset();
        const la = logged_allocator.allocator();
        try func(la, target);

        std.debug.print("{s}, {s:<14}, size: {d:5}, read: {d:8}, write: {d:8}, compare: {d:8}, alloc: {d:8}, space: {d:8}, {s}{s}\n", .{
            func_name,                                         algorithm.name(),               target.slice.len,
            target.read_count,                                 target.write_count,             target.compare_count,
            logged_allocator.alloc_count,                      logged_allocator.max_allocated, if (target.isStableSorted()) "stable " else "",
            if (target.isSorted()) "sorted" else "not sorted",
        });
        sort_succeed = sort_succeed and target.isSorted();
    }
    return sort_succeed;
}

const test_compare_length: bool = false;
pub fn testSorts(allocator: Allocator) !void {
    var target = LoggedSortTarget{};
    defer target.deinit(allocator);
    var sort_succeed = true;

    for (sort_algorithms_1) |a| {
        const name, const func = a;

        // サイズ0で動作するかどうか
        try target.resize(allocator, 0);
        try func(allocator, &target);

        // 各長さで検証
        const lengths = if (test_compare_length) [_]usize{ 0, 1, 10, 100, 1000, 10000 } else [_]usize{1000};
        for (lengths) |length| {
            try target.resize(allocator, length);
            sort_succeed = try testSortAlgorithm(&target, allocator, name, func) and sort_succeed;
        }
    }

    for (sort_algorithms_2) |a| {
        const name, const func = a;

        // サイズ0で動作するかどうか
        try target.resize(allocator, 0);
        try func(allocator, &target);

        // 各長さで検証
        const lengths = if (test_compare_length) [_]usize{ 0, 1, 10, 100 } else [_]usize{100};
        for (lengths) |length| {
            try target.resize(allocator, length);
            sort_succeed = try testSortAlgorithm(&target, allocator, name, func) and sort_succeed;
        }
    }

    for (sort_algorithms_3) |a| {
        const name, const func = a;

        // サイズ0で動作するかどうか
        try target.resize(allocator, 0);
        try func(allocator, &target);

        // 各長さで検証
        const lengths = if (test_compare_length) [_]usize{ 0, 1, 2, 4, 8 } else [_]usize{8};
        for (lengths) |length| {
            try target.resize(allocator, length);
            sort_succeed = try testSortAlgorithm(&target, allocator, name, func) and sort_succeed;
        }
    }

    if (sort_succeed) {
        std.debug.print("sort success", .{});
    } else {
        std.debug.print("sort failure", .{});
    }
}

test "sort test" {
    const allocator = std.testing.allocator;
    try testSorts(allocator);
}

// メモ: [a, b) は a を含み b を含まない値の範囲

/// 要素を逆順にする。
fn reverse(target: *LoggedSortTarget, left: usize, right: usize) void {
    const size = right - left;
    const mid = size / 2;
    for (0..mid) |i| {
        target.swap(left + i, right - i - 1);
    }
}

/// 右側二分探索。
/// [start, end) で S[i] < S[j] になる最小の j を見つけて返す。
pub fn binarySearchRightmost(target: *LoggedSortTarget, start: usize, end: usize, i: usize) usize {
    var l = start;
    var r = end;
    while (l < r) {
        const m = (l + r) / 2;
        if (target.lessThan(i, m)) { // S[i] < S[m] なら m か m より左にある。
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
        if (target.lessThan(m, i)) { // S[m] < S[i] なら m より右にある。
            l = m + 1;
        } else { // S[i] <= S[m] なら m か m より左にある。
            r = m;
        }
    }

    return l;
}

fn shuffle(target: *LoggedSortTarget) void {
    var i = target.length() - 1;
    while (0 < i) : (i -= 1) {
        const j = random(usize, 0, i + 1);
        target.swap(i, j);
    }
}

fn isSorted(target: *LoggedSortTarget) bool {
    if (target.length() < 2) return true;
    for (1..target.length()) |i| {
        if (target.lessThan(i, i - 1)) return false;
    }
    return true;
}

/// ボゴソート。
/// シャッフル→確認を繰り返す。
pub fn bogoSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    while (true) {
        shuffle(target);
        if (isSorted(target)) break;
    }
}

/// ボゾソート。
/// 要素の交換→確認を繰り返す。
pub fn bozoSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    while (true) {
        const i = random(usize, 0, target.length());
        const j = random(usize, 0, target.length());
        target.swap(i, j);
        if (isSorted(target)) break;
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
    if (target.lessThan(end - 1, mid - 1)) {
        target.swap(end - 1, mid - 1);
    }
    slowSortInternal(target, start, end - 1);
}

/// スローソート。
/// 非効率に分割統治する。
pub fn slowSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    slowSortInternal(target, 0, target.length());
}

/// バブルソート。
/// すべての要素について、隣と比較して逆順なら入れ替える。
/// 要素数-1回繰り返す。
pub fn bubbleSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |_| {
        for (1..target.length()) |j| {
            if (target.lessThan(j, j - 1)) target.swap(j, j - 1);
        }
    }
}

/// バブルソート。
/// ソート済みが確定しているところは比較を行わない。
pub fn bubbleSort2(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        for (1..target.length() - i) |j| {
            if (target.lessThan(j, j - 1)) target.swap(j, j - 1);
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

    var top: usize = 0;
    var bottom = target.length() - 1;

    while (true) {
        // 順方向
        var last_swap_index = top;

        for (top..bottom) |i| {
            if (target.lessThan(i + 1, i)) {
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
            if (target.lessThan(i, i - 1)) {
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

/// 奇偶転置ソート。
/// 奇数番目と偶数番目、偶数番目と奇数番目のペア列を交互にソートする。
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

/// ノームソート。
/// 位置を移動して前後の順序を並べる。
pub fn gnomeSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    var i: usize = 1;
    while (i < target.length()) {
        if (target.lessThan(i, i - 1)) {
            target.swap(i, i - 1);
            if (i == 1) i += 1 else i -= 1;
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
        for (i + 1..target.length()) |j| {
            if (target.lessThan(j, min_index)) {
                min_index = j;
            }
        }

        if (min_index != i) {
            target.swap(i, min_index);
        }
    }
}

/// 挿入ソート。
/// 対象の値を適切な位置に配置する。
pub fn insertionSort1(_: Allocator, target: *LoggedSortTarget) error{}!void {
    for (0..target.length()) |i| {
        var j = i;
        while (0 < j and target.lessThan(j, j - 1)) : (j -= 1) {
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
        const pos = binarySearchRightmost(target, 0, i, i);
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

const TreeSortTree = struct {
    node: LoggedSortTarget.Type,
    left: ?*TreeSortTree = null,
    right: ?*TreeSortTree = null,
};

/// ツリーに挿入する。
fn treeSortInsert(target: *LoggedSortTarget, search_tree: *?*TreeSortTree, new_node: *TreeSortTree) !void {
    if (search_tree.*) |tree| {
        if (target.compare(new_node.node, tree.node)) {
            try treeSortInsert(target, &tree.left, new_node);
        } else {
            try treeSortInsert(target, &tree.right, new_node);
        }
    } else {
        search_tree.* = new_node;
    }
}

/// ツリーの要素を配置しなおす。
fn treeSortInOrder(allocator: Allocator, target: *LoggedSortTarget, search_tree: *?*TreeSortTree, n: *usize) void {
    if (search_tree.*) |tree| {
        treeSortInOrder(allocator, target, &tree.left, n);
        target.set(n.*, tree.node);
        n.* += 1;
        treeSortInOrder(allocator, target, &tree.right, n);
        allocator.destroy(tree);
        search_tree.* = null;
    } else {
        return;
    }
}

/// ツリーソート。
/// 二分探索木を使用してソートする。
pub fn treeSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    var search_tree: ?*TreeSortTree = null;

    for (0..target.length()) |i| {
        const tree = try allocator.create(TreeSortTree);
        tree.* = TreeSortTree{ .node = target.get(i) };
        try treeSortInsert(target, &search_tree, tree);
        debug("{any}", .{search_tree});
    }

    var n: usize = 0;
    treeSortInOrder(allocator, target, &search_tree, &n);
}

/// 図書館ソート。
/// 隙間を空けて挿入ソートする。
pub fn librarySort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    // 難しそう
    _ = allocator;
    _ = target;
}

fn mergeSortMerge(target: *LoggedSortTarget, start: usize, mid: usize, end: usize, buffer: []LoggedSortTarget.Type) void {
    var left = start;
    var right = mid;

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
pub fn mergeSortInPlace3(_: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
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
    if (end <= start + 1) return;
    const partition = quickSort1Partition(target, start, end);
    quickSort2Internal(target, start, partition);
    quickSort2Internal(target, partition + 1, end);
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

    const partition = quickSort2Partition(target, start, end) + 1;
    if (partition != end) {
        quickSort2Internal(target, start, partition);
        quickSort2Internal(target, partition, end);
    }
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
fn heapSort1ShiftUp(target: *LoggedSortTarget, index: usize) void {
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
fn heapSort1ShiftDown(target: *LoggedSortTarget, index: usize, heap_size: usize) void {
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
        heapSort1ShiftUp(target, i);
    }

    i -= 1;
    while (i > 0) : (i -= 1) {
        target.swap(0, i);
        heapSort1ShiftDown(target, 0, i);
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
            heapSort1ShiftDown(target, start, target.length());
        }
    }

    {
        var end = target.length() - 1;
        while (0 < end) : (end -= 1) {
            target.swap(0, end);
            heapSort1ShiftDown(target, 0, end);
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

/// イントロソートの挿入ソート部分。
/// start .. end を挿入ソートで整列する。
fn introSortInsertion(target: *LoggedSortTarget, start: usize, end: usize) void {
    for (start..end) |i| {
        var j = i;
        while (start < j and target.lessThan(j, j - 1)) : (j -= 1) {
            target.swap(j, j - 1);
        }
    }
}

/// イントロソートのヒープソート部分。
/// start .. end をヒープソートで整列する。
fn introSortHeap(target: *LoggedSortTarget, start: usize, end: usize) void {
    const length = end - start;
    if (length < 2) return;

    {
        var n = length / 2;
        while (start < n) {
            n -= 1;
            heapSort3ShiftDown(target, n, length);
        }
    }

    {
        var n = length - 1;
        while (start < n) : (n -= 1) {
            target.swap(start, n);
            heapSort3ShiftDown(target, start, n);
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
        const partition = quickSort2Partition(target, start, end) + 1;
        if (partition != end) {
            introSortInternal(target, start, partition, max_depth - 1);
            introSortInternal(target, partition, end, max_depth - 1);
        }
    }
}

/// イントロソート。
/// クイックソートの弱点をヒープソートと挿入ソートで補う。
pub fn introSort(_: Allocator, target: *LoggedSortTarget) error{}!void {
    if (target.length() < 2) return;
    const max_depth: usize = std.math.log2_int(usize, target.length()) * 2;
    introSortInternal(target, 0, target.length(), max_depth);
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
        const pos = binarySearchRightmost(target, start, i, i);
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
    const ascend: bool = target.lessThan(start, start + 1);
    var i = start + 2;
    while (i < target.length()) {
        if (ascend == target.lessThan(i, i - 1)) {
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
    while (start + curr < end and target.lessThan(start + curr, i)) {
        prev = curr;
        curr *= 2;
    }

    return binarySearchLeftmost(target, start + prev, @min(start + curr, end), i);
}

// 二分探索で右端を見つける。
// S[i] < S[j] である最小の j を (start, end] で見つける。
fn timSortGallopRight(target: *LoggedSortTarget, start: usize, end: usize, i: usize) usize {
    var prev: usize = 0;
    var curr: usize = 1;
    while (start + curr < end and target.lessThan(i, end - curr)) {
        prev = curr;
        curr *= 2;
    }
    return binarySearchRightmost(target, @max(end -| curr, start), end -| prev, i);
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

// fn mergeInsertionSortInternal(allocator: Allocator, target: *LoggedSortTarget, start: usize, end: usize) !void {
//     // 範囲を2つに分け、ペアを大きい方と小さい方に分ける。
//     var i = start + 1;
//     while (i < end) : (i += 2) {
//         if (target.lessThan(i, i - 1)) {
//             target.swap(i - 1, i);
//         }
//     }
// }

// pub fn mergeInsertionSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
//     // 1. Group the elements of X into ⌊ n / 2 ⌋ pairs of elements, arbitrarily, leaving one element unpaired if there is an odd number of elements.
//     // 2. Perform ⌊ n / 2 ⌋ comparisons, one per pair, to determine the larger of the two elements in each pair.
//     // 3. Recursively sort the ⌊ n / 2 ⌋ larger elements from each pair, creating a sorted sequence S of ⌊ n / 2 ⌋ of the input elements, in ascending order, using the merge-insertion sort.
//     // 4. Insert at the start of S the element that was paired with the first and smallest element of S.
//     // 5. Insert the remaining ⌈ n / 2 ⌉ − 1 elements of X ∖ S into S, one at a time, with a specially chosen insertion ordering described below. Use binary search in subsequences of S (as described below) to determine the position at which each element should be inserted.
//     try mergeInsertionSortInternal(allocator, target, 0, target.length());
// }

// bucket sort
// power sort
// shear-sort
// Tournament sort
// Block sort
// Patience sort
// Cube sort
// Flux sort
// Crum sort
// Library sort
// Strand sort
// Cycle sort
// Non-recursive quicksort

// Bead sort
// Merge-insertion sort
// Spaghetti (Poll) sort
// Sorting network
// Bitonic sorter
// Unshuffle Sort

// 非比較ソート

// Pigeonhole sort
// Bucket sort
// Counting sort
// LSD Radix Sort
// MSD Radix Sort
// Spreadsort
// Burstsort
// Flashsort
