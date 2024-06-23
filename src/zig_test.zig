//! lib.zig_test
//!
//! Zig言語の基本の書き方を確認する。

const lib = @import("./root.zig");
const assert = lib.assert;

/// 使用しない変数を使用するための関数
fn consume(_: anytype) void {}

fn value(x: anytype) @TypeOf(x) {
    return x;
}

const Struct_01 = struct { x: u32, y: u32, z: u32 };
const Struct_02 = struct { x: u8 = 16, y: u8, z: u8 };
const Struct_03 = extern struct { x: u32, y: u32, z: u32 };
const Struct_04 = packed struct { x: u32, y: u32, z: u32 };
const Struct_05 = struct { u32, u32, u32 };

const Enum_01 = enum { first, second, third };
const Enum_02 = enum(u8) { first = 1, second = 2, third = 3 };
const Enum_03 = enum(u8) { first = 4, second, third };
const Enum_04 = enum(u8) { first = 1, second = 2, third = 3, _ };

const Union_01 = union { int: i32, bool: bool, void: void };
const Union_02 = union(Enum_01) { first: i32, second: bool, third: void };
const Union_03 = union(enum) { first: i32, second: bool, third: void };
const Union_04 = extern union { first: i32, second: bool, third: void };
const Union_05 = packed union { first: i32, second: bool, third: void };
const Union_06 = union(enum) {
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

const Opaque_01 = opaque {};

test {
    _ = literals;
    _ = types;
    _ = statements;
}

const literals = struct {
    test "整数リテラル 10進数" {
        _ = 42; // 10進数の整数
        _ = 1234567812345678123456781234567812345678123456781234567812345678; // リテラルは上限がない
        _ = 1_000_999; // _で区切ることができる

    }

    test "整数リテラル 2進数" {
        _ = 0b0110; // "0b" で始めると2進数
        _ = 0b1100_0011; // _で区切ることができる
    }

    test "整数リテラル 8進数" {
        _ = 0o704; // "0o" で始めると8進数
        _ = 0o567_123; // _で区切ることができる
    }

    test "整数リテラル 16進数" {
        _ = 0x1f2e; // "0x" で始めると16進数
        _ = 0x1F2E; // 大文字も使用できる
        _ = 0xabcd_ABCD; // _で区切ることができる
    }

    test "小数リテラル 10進数" {
        _ = 42.1; // 小数点付き数
        _ = 42e5; // 指数付き数
        _ = 42E5; // 大文字の指数付き数
        _ = 42e-5; // 負の指数付き数
        _ = 42.2e5; // 小数点と指数付き数
        _ = 3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647; // リテラルは上限がない
        _ = 3.1415_9265; // _で区切ることができる

    }

    test "小数リテラル 16進数" {
        _ = 0x1f2e.3d4c; // "0x" で始めると16進数
        _ = 0xabcp10; // pで指数を区切る
        _ = 0x1a_2bP-3; // _で区切ることができる
    }

    test "文字リテラル" {
        _ = 'a'; // ''で囲うと文字リテラル
        _ = '😃'; // 1つのUnicodeコードポイントを表す

        _ = '\n'; // 改行
        _ = '\r'; // キャリッジリターン
        _ = '\t'; // タブ
        _ = '\\'; // バックスラッシュ
        _ = '\''; // 単引用符
        _ = '\"'; // 二重引用符
        _ = '\x64'; // 1バイト文字
        _ = '\u{1F604}'; // Unicodeコードポイント

    }

    test "文字列リテラル" {
        _ = "abc"; // ""で囲うと文字列リテラル
        _ = "dog\r\nwolf"; // エスケープシーケンス

    }

    test "文字列リテラル 複数行" {
        // \\から後ろは複数行文字列リテラル
        _ =
            \\abc
            \\def
        ;
        // エスケープシーケンス
        _ =
            \\a\tbc
        ;
    }

    test "列挙型リテラル" {
        _ = .enum_literal;
    }

    test "構造体型リテラル" {
        _ = .{};
    }

    test "リテラルの型" {
        try assert.expectEqual(@TypeOf(42), comptime_int);
        try assert.expectEqual(@TypeOf(0b0101), comptime_int);
        try assert.expectEqual(@TypeOf(0o42), comptime_int);
        try assert.expectEqual(@TypeOf(0x42), comptime_int);

        try assert.expectEqual(@TypeOf(42.5), comptime_float);

        try assert.expectEqual(@TypeOf('a'), comptime_int);

        try assert.expectEqual(@TypeOf("abc"), *const [3:0]u8);
        try assert.expectEqual(@TypeOf(
            \\abc
        ), *const [3:0]u8);

        try assert.expectEqual(@TypeOf(.enum_literal), @TypeOf(.enum_literal));

        try assert.expectEqual(@TypeOf(.{}), @TypeOf(.{}));
    }
};

const types = struct {
    test {
        _ = primitive_types;
        _ = arrays;
        _ = vectors;
        _ = pointers;
        _ = slice;
        _ = structs;
        _ = enums;
        _ = unions;
        _ = opaques;
    }

    const primitive_types = struct {
        test "整数型" {
            // 8の倍数の整数型
            const var_01: u8 = 50;
            const var_02: u16 = 500;
            const var_03: u32 = 5000;
            const var_04: u64 = 50000;
            const var_05: u128 = 500000;
            const var_06: usize = 5000000;

            const var_07: i8 = -50;
            const var_08: i16 = -500;
            const var_09: i32 = -5000;
            const var_10: i64 = -50000;
            const var_11: i128 = -500000;
            const var_12: isize = -5000000;

            // 任意幅の整数型
            const var_13: u0 = 0;
            const var_14: i65535 = -40;

            consume(.{ var_01, var_02, var_03, var_04, var_05, var_06, var_07, var_08, var_09, var_10, var_11, var_12, var_13, var_14 });
        }

        test "浮動小数点数型" {
            const var_01: f16 = 0.01;
            const var_02: f32 = 0.001;
            const var_03: f64 = 0.0001;
            const var_04: f80 = 0.00001;
            const var_05: f128 = 0.000001;

            consume(.{ var_01, var_02, var_03, var_04, var_05 });
        }

        test "comptime_int型" {
            const var_01: comptime_int = 999_999;

            consume(.{var_01});
        }

        test "comptime_float型" {
            const var_01: comptime_float = 0.0000000009;

            consume(.{var_01});
        }

        test "bool型" {
            const var_01: bool = true;
            const var_02: bool = false;

            consume(.{ var_01, var_02 });
        }

        test "void型" {
            const var_01: void = void{};

            consume(.{var_01});
        }

        test "noreturn型" {
            while (true) {
                const var_01: noreturn = {
                    break;
                };

                consume(.{var_01});
            }
        }

        test "anyopaque型" {
            const var_01: u8 = 0;
            const var_02: *const anyopaque = @ptrCast(&var_01);

            consume(.{var_02});
        }

        test "anyerror型" {
            const var_01: anyerror = error.AnyError;

            consume(.{var_01});
        }

        test "C互換数値型" {
            const var_01: c_char = 10;
            const var_02: c_short = 20;
            const var_03: c_ushort = 30;
            const var_04: c_int = 40;
            const var_05: c_uint = 50;
            const var_06: c_long = 60;
            const var_07: c_ulong = 70;
            const var_08: c_longlong = 80;
            const var_09: c_ulonglong = 90;
            const var_10: c_longdouble = 10.5;

            consume(.{ var_01, var_02, var_03, var_04, var_05, var_06, var_07, var_08, var_09, var_10 });
        }
    };

    const arrays = struct {
        test "配列" {
            const var_01 = [3]i32{ 1, 2, 3 };
            const var_02 = [_]i32{ 1, 2, 3 }; // 要素数を省略する
            const var_03: [3]i32 = .{ 1, 2, 3 }; // 型を省略する

            consume(.{ var_01, var_02, var_03 });
        }

        test "番兵つき配列" {
            const var_01 = [3:0]i32{ 1, 2, 3 };
            const var_02 = [_:0]i32{ 1, 2, 3 }; // 要素数を省略する
            const var_03: [3:0]i32 = .{ 1, 2, 3 }; // 型を省略する

            consume(.{ var_01, var_02, var_03 });
        }
    };

    const vectors = struct {
        test "ベクトル型" {
            const var_01 = @Vector(4, i32){ 1, 2, 3, 4 }; // 整数型
            const var_02 = @Vector(4, f32){ 2.5, 3.5, 4.5, 5.5 }; // 浮動小数点数型

            var var_03: u32 = 0;
            const var_04 = @Vector(4, *u32){ &var_03, &var_03, &var_03, &var_03 }; // ポインタ型

            consume(.{ var_01, var_02, var_04 });
        }
    };

    const pointers = struct {
        test "単要素ポインタ" {
            var var_01: u32 = 45;
            const var_02: *u32 = &var_01;

            consume(.{var_02});
        }

        test "単要素定数ポインタ" {
            const var_01: u32 = 45;
            const var_02: *const u32 = &var_01;

            consume(.{var_02});
        }

        test "複数要素ポインタ" {
            var var_01: [3]u32 = .{ 45, 46, 47 };
            const var_02: [*]u32 = &var_01;

            consume(.{var_02});
        }

        test "複数要素定数ポインタ" {
            const var_01: [3]u32 = .{ 45, 46, 47 };
            const var_02: [*]const u32 = &var_01;

            consume(.{var_02});
        }

        test "番兵つき複数要素ポインタ" {
            var var_01: [3:0]u32 = .{ 45, 46, 47 };
            const var_02: [*:0]u32 = &var_01;

            consume(.{var_02});
        }

        test "番兵つき複数要素定数ポインタ" {
            const var_01: [3:0]u32 = .{ 45, 46, 47 };
            const var_02: [*:0]const u32 = &var_01;

            consume(.{var_02});
        }
    };

    const slice = struct {
        test "スライス型" {
            var var_01: [3]u32 = .{ 45, 46, 47 };
            const var_02: []u32 = &var_01;

            consume(.{var_02});
        }

        test "定数スライス型" {
            const var_01: [3]u32 = .{ 45, 46, 47 };
            const var_02: []const u32 = &var_01;

            consume(.{var_02});
        }

        test "番兵つきスライス型" {
            var var_01: [3:0]u32 = .{ 45, 46, 47 };
            const var_02: [:0]u32 = &var_01;

            consume(.{var_02});
        }

        test "番兵つき定数スライス型" {
            const var_01: [3:0]u32 = .{ 45, 46, 47 };
            const var_02: [:0]const u32 = &var_01;

            consume(.{var_02});
        }
    };

    const structs = struct {
        test "構造体型" {
            const var_01 = Struct_01{ .x = 5, .y = 10, .z = 15 };
            const var_02: Struct_01 = .{ .x = 5, .y = 10, .z = 15 };

            const var_03: Struct_02 = .{ .x = 5, .y = 10, .z = 15 };
            const var_04: Struct_02 = .{ .y = 10, .z = 15 }; // デフォルト値を使用する

            consume(.{ var_01, var_02, var_03, var_04 });
        }

        test "構造体型 C-ABIレイアウト" {
            const var_01: Struct_03 = .{ .x = 5, .y = 10, .z = 15 };

            consume(.{var_01});
        }

        test "構造体型 パックレイアウト" {
            const var_01: Struct_04 = .{ .x = 5, .y = 10, .z = 15 };

            consume(.{var_01});
        }

        test "構造体型 タプル" {
            const var_01: Struct_05 = .{ 5, 10, 15 };

            consume(.{var_01});
        }
    };

    const enums = struct {
        test "列挙型" {
            const var_01 = Enum_01.first;
            const var_02: Enum_01 = .second;

            consume(.{ var_01, var_02 });
        }

        test "列挙型 数値型つき" {
            const var_01 = Enum_02.first;
            const var_02: Enum_02 = .second;

            const var_03 = Enum_03.first;
            const var_04: Enum_03 = .second;

            consume(.{ var_01, var_02, var_03, var_04 });
        }

        test "列挙型 非網羅的" {
            const var_01 = Enum_04.first;
            const var_02: Enum_04 = .second;
            const var_03: Enum_04 = @enumFromInt(0xff);

            consume(.{ var_01, var_02, var_03 });
        }
    };

    const unions = struct {
        test "合同型" {
            const var_01 = Union_01{ .int = 123456 };
            const var_02 = Union_01{ .bool = false };
            const var_03 = Union_01{ .void = void{} };

            consume(.{ var_01, var_02, var_03 });
        }

        test "合同型 タグ付き" {
            const var_01 = Union_02{ .first = 123456 };
            const var_02 = Union_02{ .second = false };
            const var_03 = Union_02{ .third = void{} };

            const var_04 = Union_03{ .first = 123456 };
            const var_05 = Union_03{ .second = false };
            const var_06 = Union_03{ .third = void{} };

            consume(.{ var_01, var_02, var_03, var_04, var_05, var_06 });
        }

        test "合同型 C-ABIレイアウト" {
            const var_01 = Union_04{ .first = 123456 };
            const var_02 = Union_04{ .second = false };
            const var_03 = Union_04{ .third = void{} };

            consume(.{ var_01, var_02, var_03 });
        }

        test "合同型 パックレイアウト" {
            const var_01 = Union_05{ .first = 123456 };
            const var_02 = Union_05{ .second = false };
            const var_03 = Union_05{ .third = void{} };

            consume(.{ var_01, var_02, var_03 });
        }
    };

    const opaques = struct {
        test "不透明型" {
            consume(.{Opaque_01});
        }
    };
};

const statements = struct {
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
            const var_01: Union_02 = .{ .second = false };

            const result: i32 = switch (var_01) {
                .first => 1,
                .second => 2,
                .third => 3,
            };

            try assert.expectEqual(result, 2);
        }

        test "switch文 合同型 値のキャプチャ" {
            const var_01: Union_02 = .{ .second = false };

            const result: i32 = switch (var_01) {
                .first => |f| f % 5,
                .second => |s| if (s) 5 else 10,
                .third => |_| 8,
            };

            try assert.expectEqual(result, 10);
        }

        test "switch文 inline-else" {
            const var_01: Union_06 = .{ .second = .{} };

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
};

test "演算子 +" {}

test "組み込み関数 @TypeOf" {}
