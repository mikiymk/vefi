//! # 型
//!
//! Zigの型を確認する。
//!
//! ## 整数型
//!
//! - `<符号><ビットサイズ>`
//! - 符号付き(`i`)、符号なし(`u`)の2種類がある。
//! - ビットサイズは0から65535ビットまである。
//! - ポインタサイズの`usize`と`isize`がある。
//!
//! ## 浮動小数点数型
//!
//! - `f<ビットサイズ>`
//! - 半精度(16ビット)、単精度(32ビット)、倍精度(64ビット)、拡張倍精度(80ビット)、四倍精度(128ビット)の浮動小数点数型がある。
//! - IEEE-754-2008に準拠している。
//!
//! ## コンパイル時整数
//!
//! - `comptime_int`
//! - 整数リテラルとUnicodeコードポイントリテラルの型。
//! - コンパイル時に決定される。
//!
//! ## コンパイル時浮動小数点数
//!
//! - `comptime_float`
//! - 浮動小数点数リテラルの型。
//! - コンパイル時に決定される。
//!
//! ## 論理値型
//!
//! - `bool`
//! - 真偽値を表す。
//! - `true`、`false`の2種類がある。
//!
//! ## void型
//!
//! - `void`
//! - 値がないことを表す。
//!
//! ## noreturn型
//!
//! - `noreturn`
//! - 戻り値を得ることがないことを表す。

## anytype型

- `anytype`
- 任意の型。
- コンパイル時に型が決定する。

## anyopaque型

- `anyopaque`
- 任意の不透明型。
- 型の消去されたポインターに使用される。

## anyerror型

- `anyerror`
- 任意のエラー型。

## C言語互換型

- C言語のABIと互換性を持つための型。


const utils = @import("./utils.zig");
const consume = utils.consume;
const assert = utils.assert;

const Struct_01 = struct { x: u32, y: u32, z: u32 };
const Struct_02 = struct { x: u32 = 16, y: u32, z: u32 };
const Struct_03 = extern struct { x: u32, y: u32, z: u32 };
const Struct_04 = packed struct { x: u32, y: u32, z: u32 };
const Struct_05 = struct { u32, u32, u32 };

const Enum_01 = enum { first, second, third };
const Enum_02 = enum(u8) { first = 1, second = 2, third = 3 };
const Enum_03 = enum(u8) { first = 4, second, third };
const Enum_04 = enum(u8) { first = 1, second = 2, third = 3, _ };

const Union_01 = union { first: i32, second: bool, third: void };
const Union_02 = union(Enum_01) { first: i32, second: bool, third: void };
const Union_03 = union(enum) { first: i32, second: bool, third: void };
const Union_04 = extern union { first: i32, second: bool, third: void };
const Union_05 = packed union { first: i32, second: bool, third: void };

const Opaque_01 = opaque {};

const ErrorSet_01 = error{ E, R };

const ErrorUnion_01 = ErrorSet_01!u8;

const integer_01: u32 = 50;
const integer_02: i32 = -300;
const integer_03: u0 = 0;
const integer_04: i65535 = -9999;

const float_01: f16 = 0.01;
const float_02: f32 = 0.001;
const float_03: f64 = 0.0001;
const float_04: f80 = 0.00001;
const float_05: f128 = 0.000001;

const comptime_int_01: comptime_int = 999_999;

const comptime_float_01: comptime_float = 0.0000000009;

const bool_01: bool = true;
const bool_02: bool = false;

const void_01: void = void{};
const void_02: void = {};

test "noreturn" {
    while (true) {
        const noreturn_01: noreturn = {
            break;
        };

        consume(noreturn_01);
    }
}

const anyopaque_01: *const anyopaque = @ptrCast(&integer_01);

const anyerror_01: anyerror = error.AnyError;

const c_compatible_01: c_char = 10;
const c_compatible_02: c_short = 20;
const c_compatible_03: c_ushort = 30;
const c_compatible_04: c_int = 40;
const c_compatible_05: c_uint = 50;
const c_compatible_06: c_long = 60;
const c_compatible_07: c_ulong = 70;
const c_compatible_08: c_longlong = 80;
const c_compatible_09: c_ulonglong = 90;
const c_compatible_10: c_longdouble = 10.5;

const array_01 = [3]u32{ 1, 2, 3 };
/// 要素数を省略する
const array_02 = [_]u32{ 1, 2, 3 };
/// 型を省略する
const array_03: [3]u32 = .{ 1, 2, 3 };
/// 番兵付き配列
const array_04 = [3:0]u32{ 1, 2, 3 };

/// 論理値型
const vectors_01 = @Vector(4, bool){ true, false, true, false };
/// 整数型
const vectors_02 = @Vector(4, u32){ 1, 2, 3, 4 };
/// 浮動小数点数型
const vectors_03 = @Vector(4, f32){ 2.5, 3.5, 4.5, 5.5 };
/// ポインタ型
const vectors_04 = @Vector(4, *u32){ &integer_01, &integer_01, &integer_01, &integer_01 };

const single_item_pointer_01: *u32 = &integer_01;
const single_item_pointer_02: *const u32 = &integer_01;

const many_item_pointer_03: [*]u32 = &array_01;
const many_item_pointer_04: [*]const u32 = &array_01;
const many_item_pointer_05: [*:0]u32 = &array_01;
const many_item_pointer_06: [*:0]const u32 = &array_01;

const slice_01: []u32 = &array_01;
const slice_02: []const u32 = &array_01;
const slice_03: [:0]u32 = &array_01;
const slice_04: [:0]const u32 = &array_01;

/// 構造体。
const struct_01 = Struct_01{ .x = 5, .y = 10, .z = 15 };
/// 型を省略する。
const struct_02: Struct_01 = .{ .x = 5, .y = 10, .z = 15 };
/// フィールドを省略してデフォルト値を使用する。
const struct_03: Struct_02 = .{ .y = 10, .z = 15 };
/// C言語のABIと互換性のある構造体。
const struct_04: Struct_03 = .{ .x = 5, .y = 10, .z = 15 };
/// メモリレイアウトが保証される構造体。
const struct_05: Struct_04 = .{ .x = 5, .y = 10, .z = 15 };
/// タプル。
const struct_06: Struct_05 = .{ 5, 10, 15 };

const enum_01 = Enum_01.first;
const enum_02: Enum_01 = .second;
const enum_03: Enum_02 = .second;
const enum_04: Enum_03 = .second;
const enum_05: Enum_04 = .second;
const enum_06: Enum_04 = @enumFromInt(99);

test "列挙型から整数へ変換" {
    try assert(@intFromEnum(enum_03) == 2);
    try assert(@intFromEnum(enum_04) == 5);
    try assert(@intFromEnum(enum_05) == 2);
    try assert(@intFromEnum(enum_06) == 99);
}

const union_02 = Union_01{ .bool = false };
const union_03: Union_01 = .{ .void = void{} };
const union_04: Union_02 = .{ .first = 123456 };
const union_05: Union_03 = .{ .first = 123456 };
const union_06: Union_04 = .{ .first = 123456 };
const union_07: Union_05 = .{ .first = 123456 };

const opaque_01: Opaque_01 = undefined;

const optional_01: ?u8 = 5;
const optional_02: ?u8 = null;

const error_set_01 = ErrorSet_01.E;
const error_set_02: ErrorSet_01 = error.R;

fn returnError() !u8 {
    return error.R;
}

const error_union_01: ErrorUnion_01 = 5;
const error_union_02: ErrorUnion_01 = error.E;
const error_union_03 = returnError();

fn add(a: u32, b: u32) u32 {
    return a + b;
}

const function_01: fn (u32, u32) u32 = add;
const function_02: *const fn (u32, u32) u32 = add;

const n = 0;

test function_01 {
    consume(.{ function_01, function_02, &opaque_01 });
}
