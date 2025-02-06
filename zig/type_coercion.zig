const utils = @import("./utils.zig");
const assert = utils.assert;
const consume = utils.consume;

const Enum_01 = enum { first, second, third };
const Union_01 = union(Enum_01) { first: i32, second: bool, third: void };

test "整数型 小さい型 → 大きい型" {
    const var_01: u8 = 5;
    const var_02: u16 = var_01;

    consume(.{ var_01, var_02 });
}

test "整数型 符号なし → 符号付き" {
    const var_01: u8 = 5;
    const var_02: i9 = var_01;

    consume(.{ var_01, var_02 });
}

test "整数型 → 浮動小数点数型" {
    const var_01: u8 = 5;
    const var_02: f16 = var_01;

    consume(.{ var_01, var_02 });
}

test "番兵つき配列 → 配列" {
    const var_01: [3:0]u8 = .{ 1, 2, 3 };
    const var_02: [3]u8 = var_01;

    consume(.{ var_01, var_02 });
}

test "ベクトル型 → 配列" {
    const var_01: @Vector(3, u8) = .{ 1, 2, 3 };
    const var_02: [3]u8 = var_01;

    consume(.{ var_01, var_02 });
}

test "配列 → ベクトル型" {
    const var_01: [3]u8 = .{ 1, 2, 3 };
    const var_02: @Vector(3, u8) = var_01;

    consume(.{ var_01, var_02 });
}

test "ポインタ → 定数ポインタ" {
    var var_01: u8 = 5;
    const var_02: *u8 = &var_01;
    const var_03: *const u8 = var_02;

    consume(.{ var_01, var_02, var_03 });
}

test "単要素ポインタ → 要素数1の配列の単要素ポインタ" {
    var var_01: u8 = 5;
    const var_02: *const u8 = &var_01;
    const var_03: *const [1]u8 = var_02;

    consume(.{ var_01, var_02, var_03 });
}

test "配列の単要素ポインタ → 複数要素ポインタ" {
    var var_01: [3]u8 = .{ 1, 2, 3 };
    const var_02: *const [3]u8 = &var_01;
    const var_03: [*]const u8 = var_02;

    consume(.{ var_01, var_02, var_03 });
}

test "配列の単要素ポインタ → スライス型" {
    var var_01: [3]u8 = .{ 1, 2, 3 };
    const var_02: *const [3]u8 = &var_01;
    const var_03: []const u8 = var_02;

    consume(.{ var_01, var_02, var_03 });
}

test "合併型 → 列挙型" {
    const var_01: Union_01 = .{ .second = false };
    const var_02: Enum_01 = var_01;

    consume(.{ var_01, var_02 });
}

test "通常の型 → 任意型" {
    const var_01: u8 = 5;
    const var_02: ?u8 = var_01;

    consume(.{ var_01, var_02 });
}

test "エラー集合型 小さい型 → 大きい型" {
    const var_01: error{E} = error.E;
    const var_02: error{ E, R } = var_01;

    consume(.{ var_01, var_02 });
}

test "通常の型 → エラー合併型" {
    const var_01: u8 = 5;
    const var_02: error{E}!u8 = var_01;

    consume(.{ var_01, var_02 });
}
