//! 比較と入れ替えの回数をカウントする

const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const Type = struct { v: usize, i: usize };
slice: []Type = &.{},
/// 読み込み回数
read_count: usize = 0,
/// 書き込み回数
write_count: usize = 0,
/// 比較回数
compare_count: usize = 0,

pub fn deinit(self: *@This(), allocator: Allocator) void {
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
pub fn lessThanVV(self: *@This(), a: Type, b: Type) bool {
    self.compare_count += 1;
    return a.v < b.v;
}

/// S[i] < S[j] なら真を返す。
pub fn lessThanII(self: *@This(), i: usize, j: usize) bool {
    return self.lessThanVV(self.get(i), self.get(j));
}

/// S[i] < b なら真を返す。
pub fn lessThanIV(self: *@This(), i: usize, b: Type) bool {
    return self.lessThanVV(self.get(i), b);
}

/// a < S[j] なら真を返す。
pub fn lessThanVI(self: *@This(), a: Type, j: usize) bool {
    return self.lessThanVV(a, self.get(j));
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

pub const ShuffleAlgorithm = enum {
    /// すべてランダムに並びかえる。
    shuffle,
    /// 昇順にソートする。
    ascend,
    /// 降順にソートする。
    descend,
    /// ほぼ昇順にソートする。 すべての値がソート済み位置から1以内にある。
    nearly_ascend,
    /// ほぼ降順にソートする。 すべての値がソート済み位置から1以内にある。
    nearly_descend,
    /// すべて同じ値にする。
    flat,
    /// それぞれ2つずつの値のランダム順にする。
    double_shuffle,
    /// それぞれ2つずつの値の昇順にする。
    double_ascend,
    /// それぞれ2つずつの値の降順にする。
    double_descend,

    pub fn name(self: @This()) []const u8 {
        return switch (self) {
            .shuffle => "shuffle",
            .ascend => "ascend",
            .descend => "descend",
            .nearly_ascend => "nearly ascend",
            .nearly_descend => "nearly descend",
            .flat => "flat",
            .double_shuffle => "double shuffle",
            .double_ascend => "double ascend",
            .double_descend => "double descend",
        };
    }
};

/// 対象配列のサイズを変更する。
/// リサイズ後はリセット推奨。
pub fn resize(self: *@This(), allocator: Allocator, len: usize) Allocator.Error!void {
    self.slice = try allocator.realloc(self.slice, len);
}

fn shuffle(self: *@This()) void {
    lib.algorithm.shuffle.shuffle(self, lib.algorithm.random.random());
}

/// リセット用
pub fn reset(self: *@This(), shuffle_algorithm: ShuffleAlgorithm) void {
    if (self.slice.len == 0) return;

    switch (shuffle_algorithm) {
        .shuffle => {
            self.reset(.ascend);
            shuffle(self);
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
            for (self.slice) |*v| v.v = 0;
        },
        .double_shuffle => {
            self.reset(.double_ascend);
            shuffle(self);
        },
        .double_ascend => {
            for (self.slice, 0..) |*v, i| v.v = i / 2;
        },
        .double_descend => {
            for (self.slice, 0..) |*v, i| v.v = (self.slice.len - i - 1) / 2;
        },
    }
    for (self.slice, 0..) |*v, i| v.i = i;

    // カウントをリセットする。
    self.read_count = 0;
    self.write_count = 0;
    self.compare_count = 0;
}

/// ソート済みか判定する。
pub fn isSorted(self: @This()) bool {
    if (self.slice.len < 2) return true;
    for (self.slice[0 .. self.slice.len - 1], self.slice[1..]) |a, b| {
        if (a.v > b.v) return false;
    }
    return true;
}

/// ソート済みかつ安定ソートされているか判定する。
pub fn isStableSorted(self: @This()) bool {
    if (self.slice.len < 2) return true;
    if (!self.isSorted()) return false;
    for (self.slice[0 .. self.slice.len - 1], self.slice[1..]) |a, b| {
        if (a.v == b.v and a.i > b.i) return false;
    }
    return true;
}

/// 文字列に変換する
pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll(".{");
    for (self.slice, 0..) |value, i| {
        try writer.print("{s}{}", .{ if (i == 0) " " else ", ", value.v });
    }
    try writer.writeAll(" }");
}
