const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

// 連想配列の関数
// add set get delete
// has
// size clear
// keys values entries

// 連想配列の種類
// 配列・リスト
// ハッシュテーブル(チェイン法・オープンアドレス法)
// 木構造(二分木・平衡木)

pub fn HashTable(K: type, V: type) type {
    return struct {
        pub const Key = K;
        pub const Value = V;
    };
}
