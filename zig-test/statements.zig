const utils = @import("./utils.zig");
const assert = utils.assert;
const consume = utils.consume;

test {
    _ = blocks;
    _ = ifs;
    _ = switchs;
    _ = fors;
    _ = whiles;
}

const blocks = struct {
    test "ブロック文" {
        {
            consume(42);
        }
    }

    test "ブロック文 ラベル付き" {
        const var_01 = blk: {
            break :blk 42;
        };

        try assert.expectEqual(var_01, 42);
    }
};

const ifs = struct {
    test "if文" {
        const var_01: u8 = 42;
        var sum: i32 = 5;

        if (var_01 == 42) {
            sum += var_01;
        }

        try assert.expectEqual(sum, 47);
    }

    test "if文 if-else" {
        const var_01: u8 = 42;
        var sum: i32 = 5;

        if (var_01 == 42) {
            sum += var_01;
        } else {
            sum -= var_01;
        }

        try assert.expectEqual(sum, 47);
    }

    test "if文 if-else-if-else" {
        const var_01: u8 = 42;
        var sum: i32 = 5;

        if (var_01 == 42) {
            sum += var_01;
        } else if (var_01 == 0) {
            sum -= var_01;
        } else {
            sum += 30;
        }

        try assert.expectEqual(sum, 47);
    }

    test "if文 任意型" {
        const var_01: ?u8 = null;
        var sum: i32 = 5;

        if (var_01) |v| {
            sum += v;
        } else {
            sum += 99;
        }

        try assert.expectEqual(sum, 104);
    }

    test "if文 エラー合併型" {
        const var_01: error{E}!u8 = 32;
        var sum: i32 = 5;

        if (var_01) |v| {
            sum += v;
        } else |_| {
            sum += 99;
        }

        try assert.expectEqual(sum, 37);
    }
};

const switchs = struct {
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

    test "switch文 整数型" {
        const var_01: u8 = 42;
        const var_02 = 21; // コンパイル時に既知

        const result: i32 = switch (var_01) {
            1 => 1,
            2, 3, 4 => 2,
            5...7 => 3,

            var_02 => 4,
            var_02 * 2 => 5,

            else => 6,
        };

        try assert.expectEqual(result, 5);
    }

    test "switch文 整数型 網羅的" {
        const var_01: u2 = 3;

        const result: i32 = switch (var_01) {
            0 => 1,
            1, 2, 3 => 2,
        };

        try assert.expectEqual(result, 2);
    }

    test "switch文 列挙型" {
        const var_01: Enum_01 = .second;

        const result: i32 = switch (var_01) {
            .first, .second => 1,
            .third => 2,
        };

        try assert.expectEqual(result, 1);
    }

    test "switch文 列挙型 非網羅的" {
        const var_01: Enum_01 = .second;

        const result: i32 = switch (var_01) {
            .first => 1,
            else => 2,
        };

        try assert.expectEqual(result, 2);
    }

    test "switch文 合同型" {
        const var_01: Union_01 = .{ .second = false };

        const result: i32 = switch (var_01) {
            .first => 1,
            .second => 2,
            .third => 3,
        };

        try assert.expectEqual(result, 2);
    }

    test "switch文 合同型 値のキャプチャ" {
        const var_01: Union_01 = .{ .second = false };

        const result: i32 = switch (var_01) {
            .first => |f| f % 5,
            .second => |s| if (s) 5 else 10,
            .third => |_| 8,
        };

        try assert.expectEqual(result, 10);
    }

    test "switch文 inline-else" {
        const var_01: Union_02 = .{ .second = .{} };

        const result: i32 = switch (var_01) {
            inline else => |v| v.get(),
        };

        try assert.expectEqual(result, 2);
    }
};

const fors = struct {
    test "for文 配列" {
        const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        var sum: i32 = 1;

        for (var_01) |v| {
            sum += v;
        }

        try assert.expectEqual(sum, 16);
    }

    test "for文 配列の変更" {
        var var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };

        for (&var_01) |*v| {
            v.* = 6;
        }

        try assert.expectEqual(var_01[1], 6);
    }

    test "for文 配列の単要素ポインタ" {
        var var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: *[5]i32 = &var_01;
        var sum: i32 = 1;

        for (var_02) |v| {
            sum += v;
        }

        try assert.expectEqual(sum, 16);
    }

    test "for文 配列の単要素ポインタの変更" {
        var var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: *[5]i32 = &var_01;

        for (var_02) |*v| {
            v.* = 6;
        }

        try assert.expectEqual(var_02[1], 6);
    }

    test "for文 配列の単要素定数ポインタ" {
        const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: *const [5]i32 = &var_01;
        var sum: i32 = 1;

        for (var_02) |v| {
            sum += v;
        }

        try assert.expectEqual(sum, 16);
    }
    // for文 複数要素ポインタ
    // for文 番兵つき複数要素ポインタ
    test "for文 スライス型" {
        var var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: []i32 = &var_01;
        var sum: i32 = 1;

        for (var_02) |v| {
            sum += v;
        }

        try assert.expectEqual(sum, 16);
    }

    test "for文 スライス型の変更" {
        var var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: []i32 = &var_01;

        for (var_02) |*v| {
            v.* = 6;
        }

        try assert.expectEqual(var_02[1], 6);
    }

    test "for文 定数スライス型" {
        var var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: []const i32 = &var_01;
        var sum: i32 = 1;

        for (var_02) |v| {
            sum += v;
        }

        try assert.expectEqual(sum, 16);
    }

    test "for文 番兵つきスライス型" {
        var var_01: [5:0]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: [:0]i32 = &var_01;
        var sum: i32 = 1;

        for (var_02) |v| {
            sum += v;
        }

        try assert.expectEqual(sum, 16);
    }

    test "for文 番兵つきスライス型の変更" {
        var var_01: [5:0]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: [:0]i32 = &var_01;

        for (var_02) |*v| {
            v.* = 6;
        }

        try assert.expectEqual(var_02[1], 6);
    }

    test "for文 番兵つき定数スライス型" {
        var var_01: [5:0]i32 = .{ 1, 2, 3, 4, 5 };
        const var_02: [:0]const i32 = &var_01;
        var sum: i32 = 1;

        for (var_02) |v| {
            sum += v;
        }

        try assert.expectEqual(sum, 16);
    }

    test "for文 インデックス付き" {
        const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        var sum: i32 = 1;

        for (var_01, 0..) |v, i| {
            sum += v * @as(i32, @intCast(i));
        }

        try assert.expectEqual(sum, 41);
    }

    test "for文 break" {
        const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        var sum: i32 = 1;

        for (var_01) |v| {
            if (v == 4) {
                break;
            }

            sum += v;
        }

        try assert.expectEqual(sum, 7);
    }

    test "for文 continue" {
        const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        var sum: i32 = 1;

        for (var_01) |v| {
            if (v == 4) {
                continue;
            }

            sum += v;
        }

        try assert.expectEqual(sum, 12);
    }

    test "for文 else 抜け出さない場合" {
        const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        var sum: i32 = 1;

        for (var_01) |v| {
            if (v == 4) {
                continue;
            }

            sum += v;
        } else {
            sum = 99;
        }

        try assert.expectEqual(sum, 99);
    }

    test "for文 else 抜け出す場合" {
        const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };
        var sum: i32 = 1;

        for (var_01) |v| {
            if (v == 4) {
                break;
            }

            sum += v;
        } else {
            sum = 99;
        }

        try assert.expectEqual(sum, 7);
    }
};

const whiles = struct {
    test "while文" {
        var var_01: i32 = 1;
        var sum: i32 = 1;

        while (var_01 < 5) {
            var_01 += 1;
            sum += var_01;
        }

        try assert.expectEqual(sum, 15);
    }

    test "while文 break" {
        var var_01: i32 = 1;
        var sum: i32 = 1;

        while (var_01 < 5) {
            var_01 += 1;

            if (var_01 == 3) {
                break;
            }

            sum += var_01;
        }

        try assert.expectEqual(sum, 3);
    }

    test "while文 continue" {
        var var_01: i32 = 1;
        var sum: i32 = 1;

        while (var_01 < 5) {
            var_01 += 1;

            if (var_01 == 3) {
                continue;
            }

            sum += var_01;
        }

        try assert.expectEqual(sum, 12);
    }

    test "while文 コンティニュー式" {
        var var_01: i32 = 1;
        var sum: i32 = 1;

        while (var_01 < 5) : (var_01 += 1) {
            if (var_01 == 3) {
                continue;
            }

            sum += var_01;
        }

        try assert.expectEqual(sum, 8);
    }

    test "while文 else 抜け出さない場合" {
        var var_01: i32 = 1;
        var sum: i32 = 1;

        while (var_01 < 5) : (var_01 += 1) {
            if (var_01 == 3) {
                continue;
            }

            sum += var_01;
        } else {
            sum = 99;
        }

        try assert.expectEqual(sum, 99);
    }

    test "while文 else 抜け出す場合" {
        var var_01: i32 = 1;
        var sum: i32 = 1;

        while (var_01 < 5) : (var_01 += 1) {
            if (var_01 == 3) {
                break;
            }

            sum += var_01;
        } else {
            sum = 99;
        }

        try assert.expectEqual(sum, 4);
    }

    test "while文 else 値を返す" {
        var var_01: i32 = 1;

        const var_02 = while (var_01 < 5) : (var_01 += 1) {
            if (var_01 == 3) {
                break var_01;
            }
        } else 99;

        try assert.expectEqual(var_02, 3);
    }

    test "while文 任意型" {
        var var_01: ?i32 = 5;
        var sum: i32 = 1;

        while (var_01) |v| : (var_01 = if (v > 1) v - 1 else null) {
            sum += v;
        }

        try assert.expectEqual(sum, 16);
    }

    test "while文 エラー合併型" {
        var var_01: error{E}!i32 = 5;
        var sum: i32 = 1;

        while (var_01) |v| : (var_01 = if (v > 1) v - 1 else error.E) {
            sum += v;
        } else |_| {
            sum = 99;
        }

        try assert.expectEqual(sum, 99);
    }
};

test "defer文" {
    var var_01: u8 = 1;

    {
        var_01 = 5;
        defer var_01 = 6;
        var_01 = 7;
    }

    try assert.expectEqual(var_01, 6);
}

test "unreachable" {
    var var_01: u8 = 1;

    if (var_01 == 1) {
        var_01 = 5;
    } else {
        unreachable;
    }

    try assert.expectEqual(var_01, 5);
}
