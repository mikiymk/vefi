const std = @import("std");

/// 比較と入れ替えの回数をカウントする
pub const LoggedSortTarget = struct {
    slice: []usize,
    compare_count: usize = 0,
    swap_count: usize = 0,

    pub fn length(self: @This()) usize {
        return self.slice.len;
    }

    /// 位置aの値 < 位置bの値なら真を返す。
    pub fn lessThan(self: *@This(), a: usize, b: usize) bool {
        self.compare_count += 1;
        return self.slice[a] < self.slice[b];
    }

    /// 位置aと位置bの値を入れかえる。
    pub fn swap(self: *@This(), a: usize, b: usize) void {
        self.swap_count += 1;

        const tmp = self.slice[a];
        self.slice[a] = self.slice[b];
        self.slice[b] = tmp;
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
        self.compare_count = 0;
        self.swap_count = 0;

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

    pub fn dump(self: @This()) void {
        std.debug.print("length: {d} compare: {d} swap: {d} {s}\n", .{
            self.slice.len,
            self.compare_count,
            self.swap_count,
            if (self.isSorted()) "sorted" else "not sorted",
        });
    }
};

test LoggedSortTarget {
    var array: [100]usize = undefined;
    var target = LoggedSortTarget{ .slice = &array };

    target.reset(.shuffle);
    target.reset(.ascend);
    target.reset(.descend);
    target.reset(.nearly_ascend);
    target.reset(.nearly_descend);
}

fn testSortAlgorithm(func: *const fn (target: *LoggedSortTarget) void) void {
    var array: [101]usize = undefined;
    var target = LoggedSortTarget{ .slice = array[0..100] };

    std.debug.print("shuffle       ", .{});
    target.reset(.shuffle);
    func(&target);
    target.dump();

    std.debug.print("ascend        ", .{});
    target.reset(.ascend);
    func(&target);
    target.dump();

    std.debug.print("descend       ", .{});
    target.reset(.descend);
    func(&target);
    target.dump();

    std.debug.print("nearly ascend ", .{});
    target.reset(.nearly_ascend);
    func(&target);
    target.dump();

    std.debug.print("nearly descend", .{});
    target.reset(.nearly_descend);
    func(&target);
    target.dump();
}

pub fn bubbleSort(target: *LoggedSortTarget) void {
    var i: usize = 0;
    while (i < target.length()) : (i += 1) {
        var j: usize = 1;
        while (j < target.length() - i) : (j += 1) {
            if (target.lessThan(j, j - 1)) {
                target.swap(j, j - 1);
            }
        }
    }
}

test bubbleSort {
    std.debug.print("bubble sort\n", .{});
    testSortAlgorithm(bubbleSort);
}
