const std = @import("std");
const Allocator = std.mem.Allocator;

/// テスト用配列の長さ
const array_length = 10000;

/// 比較と入れ替えの回数をカウントする
pub const LoggedSortTarget = struct {
    const SortSlice = []usize;
    slice: SortSlice,
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

    /// 位置aと位置bの値を入れかえる。
    pub fn swap(self: *@This(), a: usize, b: usize) void {
        self.read_count += 2;
        self.write_count += 2;

        const tmp = self.slice[a];
        self.slice[a] = self.slice[b];
        self.slice[b] = tmp;
    }

    /// 配列を作成する。
    pub fn alloc(self: *@This(), allocator: Allocator, size: usize) Allocator.Error!SortSlice {
        self.alloc_count += 1;
        self.current_allocated += size;
        if (self.max_allocated < self.current_allocated) {
            self.max_allocated = self.current_allocated;
        }

        return allocator.alloc(usize, size);
    }

    /// 配列を解放する。
    pub fn free(self: *@This(), allocator: Allocator, slice: SortSlice) void {
        self.current_allocated -= slice.len;
        allocator.free(slice);
    }

    /// 作成した配列に値を書き出す。
    pub fn moveOut(self: *@This(), index: usize, slice: SortSlice, slice_index: usize) void {
        self.read_count += 1;
        slice[slice_index] = self.slice[index];
    }

    /// 作成した配列から値を書き入れる。
    pub fn moveIn(self: *@This(), index: usize, slice: SortSlice, slice_index: usize) void {
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

                var rng = std.Random.Xoshiro256.init(@bitCast(std.time.timestamp()));
                const random = rng.random();

                var i = self.slice.len - 1;
                while (0 < i) : (i -= 1) {
                    const j = random.intRangeAtMost(usize, 0, i);
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
        const count_length = std.fmt.comptimePrint("{}", .{std.math.log10(array_length * array_length) + 1});

        try writer.print("size: {d} read: {d:" ++
            count_length ++
            "} write: {d:" ++
            count_length ++
            "} compare: {d:" ++
            count_length ++
            "} alloc: {d:" ++
            count_length ++
            "} space: {d:" ++
            count_length ++
            "} {s}", .{
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

fn testSortAlgorithm(allocator: Allocator, func: *const fn (allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void) Allocator.Error!void {
    var array: [array_length]usize = undefined;
    var target = LoggedSortTarget{ .slice = array[0..array_length] };

    target.reset(.shuffle);
    try func(allocator, &target);
    std.debug.print("shuffle        {f}\n", .{target});

    target.reset(.ascend);
    try func(allocator, &target);
    std.debug.print("ascend         {f}\n", .{target});

    target.reset(.descend);
    try func(allocator, &target);
    std.debug.print("descend        {f}\n", .{target});

    target.reset(.nearly_ascend);
    try func(allocator, &target);
    std.debug.print("nearly ascend  {f}\n", .{target});

    target.reset(.nearly_descend);
    try func(allocator, &target);
    std.debug.print("nearly descend {f}\n", .{target});

    var empty_target = LoggedSortTarget{ .slice = &.{} };
    try func(allocator, &empty_target);
}

test "sort test" {
    const allocator = std.testing.allocator;

    std.debug.print("bubble sort 1\n", .{});
    try testSortAlgorithm(allocator, bubbleSort1);
    std.debug.print("bubble sort 2\n", .{});
    try testSortAlgorithm(allocator, bubbleSort2);
    std.debug.print("bubble sort 3\n", .{});
    try testSortAlgorithm(allocator, bubbleSort3);
    std.debug.print("shaker sort\n", .{});
    try testSortAlgorithm(allocator, shakerSort);
    std.debug.print("comb sort\n", .{});
    try testSortAlgorithm(allocator, combSort);
    std.debug.print("gnome sort\n", .{});
    try testSortAlgorithm(allocator, gnomeSort);
    std.debug.print("selection sort\n", .{});
    try testSortAlgorithm(allocator, selectionSort);
    std.debug.print("insertion sort\n", .{});
    try testSortAlgorithm(allocator, insertionSort);
    std.debug.print("shell sort\n", .{});
    try testSortAlgorithm(allocator, shellSort);
    // std.debug.print("tree sort\n", .{});
    // try testSortAlgorithm(allocator, treeSort);
    // std.debug.print("library sort\n", .{});
    // try testSortAlgorithm(allocator, librarySort);
    std.debug.print("merge sort\n", .{});
    try testSortAlgorithm(allocator, mergeSort);
}

/// バブルソート。
/// すべての要素について、隣と比較して逆順なら入れ替える。
/// 要素数-1回繰り返す。
pub fn bubbleSort1(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
    for (0..target.length()) |_| {
        for (1..target.length()) |i| {
            if (target.lessThan(i, i - 1)) {
                target.swap(i, i - 1);
            }
        }
    }
}

/// バブルソート。
/// ソート済みが確定しているところは比較を行わない。
pub fn bubbleSort2(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
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
pub fn bubbleSort3(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
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
pub fn shakerSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
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
fn divBy13(num: usize) usize {
    const result = num * 10 / 13;
    if (result == 9 or result == 10) return 11;
    return result;
}

/// コムソート。
/// 比較する2つの間隔を開けてソートする。
pub fn combSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
    var gap = divBy13(target.length());
    while (true) : (gap = divBy13(gap)) {
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
pub fn gnomeSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
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
pub fn selectionSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
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
pub fn insertionSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
    for (0..target.length()) |i| {
        var j = i;
        while (0 < j and target.lessThan(j, j - 1)) : (j -= 1) {
            target.swap(j, j - 1);
        }
    }
}

/// シェルソートの間隔を決める関数。
/// 案1. 2で割る (切り捨て)
fn shellGap1(num: usize) usize {
    return num / 2;
}
/// シェルソートの間隔を決める関数。
/// 案2. 3で割る (切り捨て)
fn shellGap2(num: usize) usize {
    return num / 3;
}
/// シェルソートの間隔を決める関数。
/// 案3. a(0)=1; a(k) = 4^k+3*2^(k-1)+1
fn shellGap3(num: usize) usize {
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
pub fn shellSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    _ = allocator;
    var gap = target.length();
    while (true) {
        gap = shellGap3(gap);
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

/// 分割されたマージソート。
fn mergeSortRange(allocator: Allocator, target: *LoggedSortTarget, start: usize, end: usize) Allocator.Error!void {
    if (end - start <= 1) return;
    const mid = (start + end) / 2;
    try mergeSortRange(allocator, target, start, mid);
    try mergeSortRange(allocator, target, mid, end);

    var left = start;
    var right = mid;

    const buffer = try target.alloc(allocator, end - start);
    var i: usize = 0;

    while (left < mid and right < end) {
        if (target.lessThan(right, left)) {
            target.moveOut(right, buffer, i);
            right += 1;
        } else {
            target.moveOut(left, buffer, i);
            left += 1;
        }
        i += 1;
    }

    // 残りを入れる
    while (left < mid) {
        target.moveOut(left, buffer, i);
        left += 1;
        i += 1;
    }
    while (right < end) {
        target.moveOut(right, buffer, i);
        right += 1;
        i += 1;
    }

    // 戻す
    for (0..buffer.len) |j| {
        target.moveIn(start + j, buffer, j);
    }
    target.free(allocator, buffer);
}

/// マージソート。
/// 分割して結合を繰り返す。
pub fn mergeSort(allocator: Allocator, target: *LoggedSortTarget) Allocator.Error!void {
    try mergeSortRange(allocator, target, 0, target.length());
}
