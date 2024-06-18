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
}

test "整数型" {
    // 8の倍数の整数型
    const var_01: u8 = 50;
    const var_02: u16 = 500;
    const var_03: u32 = 5000;
    const var_04: u64 = 50000;
    const var_05: u128 = 500000;
    const var_06: i8 = -50;
    const var_07: i16 = -500;
    const var_08: i32 = -5000;
    const var_09: i64 = -50000;
    const var_10: i128 = -500000;

    // 任意幅の整数型
    const var_11: u0 = 0;
    const var_12: i65535 = -40;

    consume(.{ var_01, var_02, var_03, var_04, var_05, var_06, var_07, var_08, var_09, var_10, var_11, var_12 });
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

test "ベクトル型" {
    const var_01 = @Vector(4, i32){ 1, 2, 3, 4 }; // 整数型
    const var_02 = @Vector(4, f32){ 2.5, 3.5, 4.5, 5.5 }; // 浮動小数点数型

    var var_03: u32 = 0;
    const var_04 = @Vector(4, *u32){ &var_03, &var_03, &var_03, &var_03 }; // ポインタ型

    consume(.{ var_01, var_02, var_04 });
}

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

test "構造体型" {
    const Struct_01 = struct { x: u32, y: u32, z: u32 };
    const var_01 = Struct_01{ .x = 5, .y = 10, .z = 15 };
    const var_02: Struct_01 = .{ .x = 5, .y = 10, .z = 15 };

    const Struct_02 = struct { r: u8 = 16, g: u8, b: u8, a: u8 };
    const var_03: Struct_02 = .{ .r = 5, .g = 10, .b = 15, .a = 20 };
    const var_04: Struct_02 = .{ .g = 10, .b = 15, .a = 20 }; // デフォルト値を使用する

    consume(.{ var_01, var_02, var_03, var_04 });
}
test "構造体型 C-ABIレイアウト" {
    const Struct_01 = extern struct { x: u32, y: u32, z: u32 };
    const var_01: Struct_01 = .{ .x = 5, .y = 10, .z = 15 };

    consume(.{var_01});
}
test "構造体型 パックレイアウト" {
    const Struct_01 = packed struct { x: u32, y: u32, z: u32 };
    const var_01: Struct_01 = .{ .x = 5, .y = 10, .z = 15 };

    consume(.{var_01});
}
test "構造体型 タプル" {
    const Struct_01 = struct { u32, u32, u32 };
    const var_01: Struct_01 = .{ 5, 10, 15 };

    consume(.{var_01});
}

test "列挙型" {
    const Enum_01 = enum { first, second, third };
    const var_01 = Enum_01.first;
    const var_02: Enum_01 = .second;

    consume(.{ var_01, var_02 });
}
test "列挙型 数値型つき" {
    const Enum_01 = enum(u8) { first = 1, second = 2, third = 3 };
    const var_01 = Enum_01.first;
    const var_02: Enum_01 = .second;

    const Enum_02 = enum(u8) { first = 4, second, third };
    const var_03 = Enum_02.first;
    const var_04: Enum_02 = .second;

    consume(.{ var_01, var_02, var_03, var_04 });
}
test "列挙型 非網羅的" {
    const Enum_01 = enum(u8) { first = 1, second = 2, third = 3, _ };
    const var_01 = Enum_01.first;
    const var_02: Enum_01 = .second;
    const var_03: Enum_01 = @enumFromInt(0xff);

    consume(.{ var_01, var_02, var_03 });
}

test "合同型" {
    const Union_01 = union { int: i32, bool: bool, void: void };
    const var_01 = Union_01{ .int = 123456 };
    const var_02 = Union_01{ .bool = false };
    const var_03 = Union_01{ .void = void{} };

    consume(.{ var_01, var_02, var_03 });
}
test "合同型 タグ付き" {
    const Enum_01 = enum { int, bool, void };
    const Union_02 = union(Enum_01) { int: i32, bool: bool, void: void };
    const var_01 = Union_02{ .int = 123456 };
    const var_02 = Union_02{ .bool = false };
    const var_03 = Union_02{ .void = void{} };

    const Union_03 = union(enum) { int: i32, bool: bool, void: void };
    const var_04 = Union_03{ .int = 123456 };
    const var_05 = Union_03{ .bool = false };
    const var_06 = Union_03{ .void = void{} };

    consume(.{ var_01, var_02, var_03, var_04, var_05, var_06 });
}
test "合同型 C-ABIレイアウト" {
    const Union_01 = extern union { int: i32, bool: bool, void: void };
    const var_01 = Union_01{ .int = 123456 };
    const var_02 = Union_01{ .bool = false };
    const var_03 = Union_01{ .void = void{} };

    consume(.{ var_01, var_02, var_03 });
}
test "合同型 パックレイアウト" {
    const Union_01 = packed union { int: i32, bool: bool, void: void };
    const var_01 = Union_01{ .int = 123456 };
    const var_02 = Union_01{ .bool = false };
    const var_03 = Union_01{ .void = void{} };

    consume(.{ var_01, var_02, var_03 });
}

test "不透明型" {
    const Opaque_01 = opaque {};

    consume(.{Opaque_01});
}

test "ブロック文" {
    {
        consume(42);
    }
}
test "ブロック文 ラベル付き" {
    blk: {
        consume(42);

        break :blk;
    }
}

test "if文" {
    const var_01: u8 = 42;

    if (var_01 == 42) {
        consume(var_01);
    }
}
test "if文 if-else" {
    const var_01: u8 = 42;

    if (var_01 == 42) {
        consume(var_01);
    } else {
        consume(100);
    }
}
test "if文 if-else-if-else" {
    const var_01: u8 = 42;

    if (var_01 == 42) {
        consume(var_01);
    } else if (var_01 == 0) {
        consume(-42);
    } else {
        consume(100);
    }
}

test "switch文 整数型" {
    const var_01: u8 = 42;
    const var_02 = 10; // コンパイル時に既知

    _ = switch (var_01) {
        1 => 1,
        2, 3, 4 => 2,
        5...7 => 3,

        var_02 => 4,
        var_02 * 2 => 5,

        else => 6,
    };
}
test "switch文 整数型 網羅的" {
    const var_01: u2 = 3;

    _ = switch (var_01) {
        0 => 1,
        1, 2, 3 => 2,
    };
}
test "switch文 列挙型" {
    const Enum_01 = enum { first, second, third };
    const var_01: Enum_01 = .second;

    _ = switch (var_01) {
        .first, .second => 1,
        .third => 2,
    };
}
test "switch文 列挙型 非網羅的" {
    const Enum_01 = enum { first, second, third };
    const var_01: Enum_01 = .second;

    _ = switch (var_01) {
        .first => 1,
        else => 2,
    };
}
test "switch文 合同型" {
    const Enum_01 = enum { first, second, third };
    const var_01: Enum_01 = .second;

    _ = switch (var_01) {
        .first => 1,
        else => 2,
    };
}

test "for文" {
    const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };

    for (var_01) |v| {
        consume(v);
    }
}
test "for文 for-else" {
    const var_01: [5]i32 = .{ 1, 2, 3, 4, 5 };

    for (var_01) |v| {
        consume(v);
    } else {
        consume(var_01);
    }
}

test "while文" {
    var var_01: i32 = 1;

    while (var_01 > 0) {
        var_01 *%= 2;
    }
}

test "defer文" {}

test "演算子 +" {}

test "組み込み関数 @TypeOf" {}
