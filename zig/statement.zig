const utils = @import("./utils.zig");
const assert = utils.assert;
const consume = utils.consume;

const Enum_01 = enum { first, second, third };

const Union_01 = union(Enum_01) { first: i32, second: bool, third: void };
const Union_02 = union(enum) {
    first: struct {
        pub fn get(_: @This()) i32 {
            return 1;
        }
    },
    second: struct {
        pub fn get(_: @This()) i32 {
            return 2;
        }
    },
    third: struct {
        pub fn get(_: @This()) i32 {
            return 3;
        }
    },
};

test "ブロック文" {
    {
        consume(42);
    }
}

test "ブロック文 ラベル" {
    blk: {
        break :blk;
    }
}

test "ブロック文 値を返す" {
    const value_01 = blk: {
        break :blk 42;
    };

    try assert(value_01 == 42);
}

test "if文" {
    const value_01: u8 = 42;
    var sum: i32 = 5;

    if (value_01 == 42) {
        sum += value_01;
    }

    try assert(sum == 47);
}

test "if文 else" {
    const value_01: u8 = 42;
    var sum: i32 = 5;

    if (value_01 == 42) {
        sum += value_01;
    } else {
        sum -= value_01;
    }

    try assert(sum == 47);
}

test "if文 else-if" {
    const value_01: u8 = 42;
    var sum: i32 = 5;

    if (value_01 == 42) {
        sum += value_01;
    } else if (value_01 == 0) {
        sum -= value_01;
    } else {
        sum += 30;
    }

    try assert(sum == 47);
}

test "if文 オプション型" {
    const value_01: ?u8 = null;
    var value_02: i32 = 0;

    if (value_01) |v| {
        value_02 = v;
    } else {
        value_02 = 99;
    }

    try assert(value_02 == 99);
}

test "if文 エラー合併型" {
    const value_01: error{E}!u8 = 32;
    var value_02: i32 = 0;

    if (value_01) |v| {
        value_02 = v;
    } else |_| {
        value_02 = 99;
    }

    try assert(value_02 == 32);
}

test "if文 値を返す" {
    const value_01: u8 = 30;
    const value_02 = if (15 < value_01) 1 else 2;

    try assert(value_02 == 1);
}

test "switch文 整数型 elseなし" {
    const value_01: u2 = 3;

    const result: i32 = switch (value_01) {
        0 => 1,
        1, 2, 3 => 2,
    };

    try assert(result == 2);
}

test "switch文 整数型 elseあり" {
    const value_01: u8 = 42;
    const value_02 = 21; // コンパイル時に既知

    var result: i32 = 0;
    switch (value_01) {
        1 => result = 1,
        2, 3, 4 => result = 2,
        5...7 => result = 3,

        value_02 => result = 4,
        value_02 * 2 => result = 5,

        else => result = 6,
    }

    try assert(result == 5);
}

test "switch文 列挙型 elseなし" {
    const value_01: Enum_01 = .second;

    const result: i32 = switch (value_01) {
        .first, .second => 1,
        .third => 2,
    };

    try assert(result == 1);
}

test "switch文 列挙型 elseあり" {
    const value_01: Enum_01 = .second;

    const result: i32 = switch (value_01) {
        .first => 1,
        else => 2,
    };

    try assert(result == 2);
}

test "switch文 合同型" {
    const value_01: Union_01 = .{ .second = false };

    const result: i32 = switch (value_01) {
        .first => 1,
        .second => 2,
        .third => 3,
    };

    try assert(result == 2);
}

test "switch文 合同型 値のキャプチャ" {
    const value_01: Union_01 = .{ .second = false };

    const result: i32 = switch (value_01) {
        .first => |f| f % 5,
        .second => |s| if (s) 5 else 10,
        .third => |_| 8,
    };

    try assert(result == 10);
}

test "switch文 inline-else" {
    const value_01: Union_02 = .{ .second = .{} };

    const result: i32 = switch (value_01) {
        inline else => |v| v.get(),
    };

    try assert(result == 2);
}

test "for文 配列" {
    const value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    var sum: i32 = 1;

    for (value_01) |v| {
        sum += v;
    }

    try assert(sum == 16);
}

test "for文 配列の変更" {
    var value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };

    for (&value_01) |*v| {
        v.* = 6;
    }

    try assert(value_01[1] == 6);
}

test "for文 配列の単要素ポインタ" {
    var value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: *[5]i32 = &value_01;
    var sum: i32 = 1;

    for (value_02) |v| {
        sum += v;
    }

    try assert(sum == 16);
}

test "for文 配列の単要素ポインタの変更" {
    var value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: *[5]i32 = &value_01;

    for (value_02) |*v| {
        v.* = 6;
    }

    try assert(value_02[1] == 6);
}

test "for文 配列の単要素定数ポインタ" {
    const value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: *const [5]i32 = &value_01;
    var sum: i32 = 1;

    for (value_02) |v| {
        sum += v;
    }

    try assert(sum == 16);
}
// for文 複数要素ポインタ
// for文 番兵つき複数要素ポインタ
test "for文 スライス型" {
    var value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: []i32 = &value_01;
    var sum: i32 = 1;

    for (value_02) |v| {
        sum += v;
    }

    try assert(sum == 16);
}

test "for文 スライス型の変更" {
    var value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: []i32 = &value_01;

    for (value_02) |*v| {
        v.* = 6;
    }

    try assert(value_02[1] == 6);
}

test "for文 定数スライス型" {
    var value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: []const i32 = &value_01;
    var sum: i32 = 1;

    for (value_02) |v| {
        sum += v;
    }

    try assert(sum == 16);
}

test "for文 番兵つきスライス型" {
    var value_01: [5:0]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: [:0]i32 = &value_01;
    var sum: i32 = 1;

    for (value_02) |v| {
        sum += v;
    }

    try assert(sum == 16);
}

test "for文 番兵つきスライス型の変更" {
    var value_01: [5:0]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: [:0]i32 = &value_01;

    for (value_02) |*v| {
        v.* = 6;
    }

    try assert(value_02[1] == 6);
}

test "for文 番兵つき定数スライス型" {
    var value_01: [5:0]i32 = .{ 1, 2, 3, 4, 5 };
    const value_02: [:0]const i32 = &value_01;
    var sum: i32 = 1;

    for (value_02) |v| {
        sum += v;
    }

    try assert(sum == 16);
}

test "for文 インデックス付き" {
    const value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    var sum: i32 = 1;

    for (value_01, 0..) |v, i| {
        sum += v * @as(i32, @intCast(i));
    }

    try assert(sum == 41);
}

test "for文 break" {
    const value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    var sum: i32 = 1;

    for (value_01) |v| {
        if (v == 4) {
            break;
        }

        sum += v;
    }

    try assert(sum == 7);
}

test "for文 continue" {
    const value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    var sum: i32 = 1;

    for (value_01) |v| {
        if (v == 4) {
            continue;
        }

        sum += v;
    }

    try assert(sum == 12);
}

test "for文 else 抜け出さない場合" {
    const value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    var sum: i32 = 1;

    for (value_01) |v| {
        if (v == 4) {
            continue;
        }

        sum += v;
    } else {
        sum = 99;
    }

    try assert(sum == 99);
}

test "for文 else 抜け出す場合" {
    const value_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
    var sum: i32 = 1;

    for (value_01) |v| {
        if (v == 4) {
            break;
        }

        sum += v;
    } else {
        sum = 99;
    }

    try assert(sum == 7);
}

test "while文" {
    var value_01: i32 = 1;
    var sum: i32 = 1;

    while (value_01 < 5) {
        value_01 += 1;
        sum += value_01;
    }

    try assert(sum == 15);
}

test "while文 break" {
    var value_01: i32 = 1;
    var sum: i32 = 1;

    while (value_01 < 5) {
        value_01 += 1;

        if (value_01 == 3) {
            break;
        }

        sum += value_01;
    }

    try assert(sum == 3);
}

test "while文 continue" {
    var value_01: i32 = 1;
    var sum: i32 = 1;

    while (value_01 < 5) {
        value_01 += 1;

        if (value_01 == 3) {
            continue;
        }

        sum += value_01;
    }

    try assert(sum == 12);
}

test "while文 コンティニュー式" {
    var value_01: i32 = 1;
    var sum: i32 = 1;

    while (value_01 < 5) : (value_01 += 1) {
        if (value_01 == 3) {
            continue;
        }

        sum += value_01;
    }

    try assert(sum == 8);
}

test "while文 else 抜け出さない場合" {
    var value_01: i32 = 1;
    var sum: i32 = 1;

    while (value_01 < 5) : (value_01 += 1) {
        if (value_01 == 3) {
            continue;
        }

        sum += value_01;
    } else {
        sum = 99;
    }

    try assert(sum == 99);
}

test "while文 else 抜け出す場合" {
    var value_01: i32 = 1;
    var sum: i32 = 1;

    while (value_01 < 5) : (value_01 += 1) {
        if (value_01 == 3) {
            break;
        }

        sum += value_01;
    } else {
        sum = 99;
    }

    try assert(sum == 4);
}

test "while文 else 値を返す" {
    var value_01: i32 = 1;

    const value_02 = while (value_01 < 5) : (value_01 += 1) {
        if (value_01 == 3) {
            break value_01;
        }
    } else 99;

    try assert(value_02 == 3);
}

test "while文 任意型" {
    var value_01: ?i32 = 5;
    var sum: i32 = 1;

    while (value_01) |v| : (value_01 = if (v > 1) v - 1 else null) {
        sum += v;
    }

    try assert(sum == 16);
}

test "while文 エラー合併型" {
    var value_01: error{E}!i32 = 5;
    var sum: i32 = 1;

    while (value_01) |v| : (value_01 = if (v > 1) v - 1 else error.E) {
        sum += v;
    } else |_| {
        sum = 99;
    }

    try assert(sum == 99);
}

test "defer文" {
    var value_01: u8 = 1;

    {
        value_01 = 5;
        defer value_01 = 6;
        value_01 = 7;
    }

    try assert(value_01 == 6);
}

test "unreachable" {
    var value_01: u8 = 1;

    if (value_01 == 1) {
        value_01 = 5;
    } else {
        unreachable;
    }

    try assert(value_01 == 5);
}

test "後置 ()" {
    const function: fn () void = struct {
        pub fn f() void {}
    }.f;

    function();
}

test "後置 単項 .*" {
    const var_01: u8 = 5;
    const var_02: *const u8 = &var_01;
    const var_03: u8 = var_02.*;

    try assert(var_03 == 5);
}

test "インデックス" {
    var var_01: [3]u8 = .{ 1, 2, 3 };
    var var_02: @Vector(3, u8) = .{ 1, 2, 3 };
    var var_03: struct { u8, u8, u8 } = .{ 1, 2, 3 };
    const var_04: *[3]u8 = &var_01;
    const var_05: *@Vector(3, u8) = &var_02;
    const var_06: *struct { u8, u8, u8 } = &var_03;
    const var_07: []u8 = &var_01;
    const var_08: [*]u8 = &var_01;
    const var_09: [*c]u8 = &var_01;

    try assert(var_01[0] == 1);
    try assert(var_02[0] == 1);
    try assert(var_03[0] == 1);
    try assert(var_04[0] == 1);
    try assert(var_05[0] == 1);
    try assert(var_06[0] == 1);
    try assert(var_07[0] == 1);
    try assert(var_08[0] == 1);
    try assert(var_09[0] == 1);
}

test "インデックス 開始〜終了" {
    const equalSlices = utils.equalSlices;

    var var_01: [3]u8 = .{ 1, 2, 3 };
    const var_02: *[3]u8 = &var_01;
    const var_03: []u8 = &var_01;
    const var_04: [*]u8 = &var_01;
    const var_05: [*c]u8 = &var_01;

    try assert(equalSlices(var_01[0..2], &.{ 1, 2 }));
    try assert(equalSlices(var_02[0..2], &.{ 1, 2 }));
    try assert(equalSlices(var_03[0..2], &.{ 1, 2 }));
    try assert(equalSlices(var_04[0..2], &.{ 1, 2 }));
    try assert(equalSlices(var_05[0..2], &.{ 1, 2 }));

    const var_06: *u8 = &var_01[0];
    try assert(equalSlices(var_06[0..0], &.{}));
    try assert(equalSlices(var_06[0..1], &.{1}));
    try assert(equalSlices(var_06[1..1], &.{}));
}

test "インデックス 開始〜" {
    const equalSlices = utils.equalSlices;

    var var_01: [3]u8 = .{ 1, 2, 3 };
    const var_02: *[3]u8 = &var_01;
    const var_03: []u8 = &var_01;
    const var_04: [*]u8 = &var_01;
    const var_05: [*c]u8 = &var_01;

    try assert(equalSlices(var_01[1..], &.{ 2, 3 }));
    try assert(equalSlices(var_02[1..], &.{ 2, 3 }));
    try assert(equalSlices(var_03[1..], &.{ 2, 3 }));

    const var_06 = var_04[1..];
    try assert(var_06[0] == 2);
    try assert(var_06[1] == 3);

    const var_07 = var_05[1..];
    try assert(var_07[0] == 2);
    try assert(var_07[1] == 3);
}

test "後置 単項 .?" {
    const var_01: ?u8 = 5;
    const var_02: u8 = var_01.?;

    try assert(var_02 == 5);
}
