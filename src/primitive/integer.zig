//! (lib.primitive.integer)
//!
//! 整数型の操作する関数を与えます。
//!
//! # 整数型について
//!
//! 整数型に含まれる型は以下にリストされます。
//!
//! - ビットサイズの指定された符号あり整数型 (`i0`から`i65535`)
//! - ビットサイズの指定された符号なし整数型 (`u0`から`u65535`)
//! - ポインタサイズの符号あり整数型 (`isize`)
//! - ポインタサイズの符号なし整数型 (`usize`)
//! - コンパイル時整数型 (`comptime_int`)
//!
//! 符号あり整数型は2の補数表現で表されます。
//!
//! ## 整数型の暗黙的な型変換
//!
//! 1つの整数型(A)がもう1つの整数型(B)の値をすべて表現できるとき、B型の値はA型の値として使用できます。
//!
//! # 整数型の演算について
//!
//! ## 足し算 (`+`)
//!
//! 二つの整数の和を返します。
//! 結果がその整数型で表せない場合、未定義動作になります。
//!
//! - コンパイル時に値がわかっている場合、コンパイルエラーを起こす。
//! - コンパイル時に値がわからず、ランタイム安全性が有効な場合、パニックを起こす。
//! - コンパイル時に値がわからず、ランタイム安全性が無効な場合、ラップアラウンド動作を起こす。
//!
//! ## 足し算 ラップアラウンド (`+%`)
//!
//! 二つの整数の和を返します。
//! 結果がその整数型で表せない場合、ラップアラウンド動作になります。
//!
//! - 型の最大値の1つ上は型の最小値になります。
//! - 型の最小値の1つ下は型の最大値になります。
//!

const std = @import("std");
const lib = @import("../lib.zig");

const assert = lib.assert.assert;
const expect = lib.assert.expect;
const expectEqual = lib.assert.expectEqual;
const expectEqualWithType = lib.assert.expectEqualWithType;

/// このデータ構造は Zig 言語コード生成で使用されるため、コンパイラー実装と同期を保つ必要があります。
pub const Signedness = std.builtin.Signedness;

pub const OverflowError = error{IntegerOverflow};
pub const DivZeroError = error{DivideByZero};

const negation_error_message = "符号反転は符号あり整数型である必要があります。";

// 定数

pub const POINTER_SIZE = sizeOf(usize);

// 整数型を作る関数

/// 符号とビット数から整数型を返します。
pub fn Integer(signedness: Signedness, bits: u16) type {
    return @Type(.{ .Int = .{
        .signedness = signedness,
        .bits = bits,
    } });
}

/// 整数型を受け取り、同じビット数の符号あり整数を返します。
pub fn Signed(T: type) type {
    return Integer(.signed, sizeOf(T));
}

/// 整数型を受け取り、同じビット数の符号なし整数を返します。
pub fn Unsigned(T: type) type {
    return Integer(.unsigned, sizeOf(T));
}

/// ビット数をnビット増やした同じ符号の整数を返します。
fn Extend(T: type, n: i17) type {
    return Integer(signOf(T), cast(u16, sizeOf(T) + n) catch |e| switch (e) {
        error.IntegerOverflow => std.debug.panic("value {d} is not in the u16 range.", .{sizeOf(T) + n}),
    });
}

test "符号とビットサイズから整数型を作成する" {
    const IntType: type = Integer(.signed, 16);
    try expectEqual(IntType, i16);
}

// 整数型の種類を調べる関数

/// 型が符号あり整数型かどうかを判定します。
///
/// 符号あり整数型(`i0`から`i65535`、 または`isize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isSignedInteger(T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => |i| i.signedness == .signed,
        else => false,
    };
}

/// 型が符号なし整数型かどうかを判定します。
///
/// 符号なし整数型(`u0`から`u65535`、 または`usize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isUnsignedInteger(T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => |i| i.signedness == .unsigned,
        else => false,
    };
}

/// 型がビットサイズの整数型かどうかを判定します。
///
/// ビットサイズの指定された整数型(`i0`から`i65535`、 または`u0`から`u65535`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isBitSizedInteger(T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => T != usize and T != isize,
        else => false,
    };
}

/// 型がポインタサイズの整数型かどうかを判定します。
///
/// ポインタサイズの整数型(`isize`、 または`usize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isPointerSizedInteger(T: type) bool {
    return T == usize or T == isize;
}

/// 型が実行時整数(`comptime_int`以外の整数型)かどうかを判定します。
pub fn isRuntimeInteger(T: type) bool {
    const info = @typeInfo(T);

    return info == .Int;
}

/// 型がコンパイル時整数(`comptime_int`)かどうかを判定します。
pub fn isComptimeInteger(T: type) bool {
    const info = @typeInfo(T);

    return info == .ComptimeInt;
}

/// 型が整数かどうかを判定します。
pub fn isInteger(T: type) bool {
    const info = @typeInfo(T);

    return info == .Int or info == .ComptimeInt;
}

/// 整数型の符号を調べます。
pub fn signOf(T: type) Signedness {
    assert(isRuntimeInteger(T));

    return @typeInfo(T).Int.signedness;
}

/// 整数型のビットサイズを調べます。
pub fn sizeOf(T: type) u16 {
    assert(isRuntimeInteger(T));

    return @typeInfo(T).Int.bits;
}

test "型を調べる関数" {
    try expect(isSignedInteger(i32));
    try expect(!isSignedInteger(u32));
    try expect(!isSignedInteger(f32));
    try expect(isSignedInteger(isize));
    try expect(!isSignedInteger(usize));
    try expect(!isSignedInteger(comptime_int));

    try expect(!isUnsignedInteger(i32));
    try expect(isUnsignedInteger(u32));
    try expect(!isUnsignedInteger(f32));
    try expect(!isUnsignedInteger(isize));
    try expect(isUnsignedInteger(usize));
    try expect(!isUnsignedInteger(comptime_int));

    try expect(isBitSizedInteger(i32));
    try expect(isBitSizedInteger(u32));
    try expect(!isBitSizedInteger(f32));
    try expect(!isBitSizedInteger(isize));
    try expect(!isBitSizedInteger(usize));
    try expect(!isBitSizedInteger(comptime_int));

    try expect(!isPointerSizedInteger(i32));
    try expect(!isPointerSizedInteger(u32));
    try expect(!isPointerSizedInteger(f32));
    try expect(isPointerSizedInteger(isize));
    try expect(isPointerSizedInteger(usize));
    try expect(!isPointerSizedInteger(comptime_int));

    try expect(!isComptimeInteger(i32));
    try expect(!isComptimeInteger(u32));
    try expect(!isComptimeInteger(f32));
    try expect(!isComptimeInteger(isize));
    try expect(!isComptimeInteger(usize));
    try expect(isComptimeInteger(comptime_int));

    try expect(isInteger(i32));
    try expect(isInteger(u32));
    try expect(!isInteger(f32));
    try expect(isInteger(isize));
    try expect(isInteger(usize));
    try expect(isInteger(comptime_int));

    try expect(sizeOf(i32) == 32);
    try expect(sizeOf(u32) == 32);
    _ = sizeOf(usize);

    try expect(isInteger(c_char));
    try expect(isInteger(c_short));
    try expect(isInteger(c_ushort));
    try expect(isInteger(c_int));
    try expect(isInteger(c_uint));
    try expect(isInteger(c_long));
    try expect(isInteger(c_ulong));
    try expect(isInteger(c_longlong));
    try expect(isInteger(c_ulonglong));
}

// 整数型の最大値と最小値を求める関数

/// 与えられた整数型の表現できる最大の整数を返します。
pub fn max(T: type) T {
    assert(isRuntimeInteger(T));

    return switch (comptime signOf(T)) {
        .unsigned => ~@as(T, 0),
        .signed => ~@as(Unsigned(T), 0) >> 1,
    };
}

/// 与えられた整数型の表現できる最小の整数を返します。
pub fn min(T: type) T {
    assert(isRuntimeInteger(T));

    return switch (comptime signOf(T)) {
        .unsigned => 0,
        .signed => ~max(T),
    };
}

test "最大値と最小値" {
    try expectEqual(max(u8), 0xff);
    try expectEqual(min(u8), 0);

    try expectEqual(max(i8), 0x7f);
    try expectEqual(min(i8), -0x80);
}

/// 値を指定した型に変換します。
/// 値が型の上限より大きい場合はエラーを返します。
pub fn cast(T: type, value: anytype) OverflowError!T {
    assert(isRuntimeInteger(T) and isRuntimeInteger(@TypeOf(value)));

    if (max(T) < value or value < min(T)) {
        return OverflowError.IntegerOverflow;
    }

    return @intCast(value);
}

/// 値を指定した型に変換します。
/// 値が型の上限より大きい場合は剰余の値を返します。
pub fn castTruncate(T: type, value: anytype) T {
    assert(isRuntimeInteger(T) and isRuntimeInteger(@TypeOf(value)));

    return @truncate(value);
}

/// 値を指定した型に変換します。
/// 値が型の上限より大きい場合は最大値・最小値に制限されます。
pub fn castSaturation(T: type, value: anytype) T {
    assert(isRuntimeInteger(T) and isRuntimeInteger(@TypeOf(value)));

    if (max(T) < value) {
        return max(T);
    } else if (value < min(T)) {
        return min(T);
    }

    return @intCast(value);
}

/// 値を指定した型に変換します。
/// 値が型の上限より大きい場合は未定義動作になります。
pub fn castUnsafe(T: type, value: anytype) T {
    assert(isRuntimeInteger(T) and isRuntimeInteger(@TypeOf(value)));

    return @intCast(value);
}

test "型キャスト" {
    const foo1: u9 = 1;
    const foo2: u16 = 0xfff;
    const foo3: i8 = -1;
    const foo4: i9 = -1;

    try expectEqual(cast(u8, foo1), 1);
    try expectEqual(cast(u8, foo2), error.IntegerOverflow);
    try expectEqual(cast(u8, foo3), error.IntegerOverflow);
    try expectEqual(cast(u8, foo4), error.IntegerOverflow);

    try expectEqual(castTruncate(u8, foo1), 1);
    try expectEqual(castTruncate(u8, foo2), 0xff);
    // try expectEqual(castTruncate(u8, foo3), 0xff); // build error: expected unsigned integer type, found 'i8'
    // try expectEqual(castTruncate(u8, foo4), 0xff); // build error: expected unsigned integer type, found 'i9'

    try expectEqual(castSaturation(u8, foo1), 1);
    try expectEqual(castSaturation(u8, foo2), 0xff);
    try expectEqual(castSaturation(u8, foo3), 0);
    try expectEqual(castSaturation(u8, foo4), 0);
}

/// 値のビットを符号あり整数型として返します。
pub fn asSigned(T: type, value: T) Signed(T) {
    assert(isUnsignedInteger(T));

    return @bitCast(value);
}

/// 値のビットを符号なし整数型として返します。
pub fn asUnsigned(T: type, value: T) Unsigned(T) {
    assert(isSignedInteger(T));

    return @bitCast(value);
}

test "ビット型変換" {
    try expectEqual(asSigned(u8, 0x80), -0x80);
    try expectEqual(asSigned(u8, 0xff), -1);

    try expectEqual(asUnsigned(i8, -1), 0xff);
    try expectEqual(asUnsigned(i8, -0x80), 0x80);
}

// 符号反転

/// 整数型の符号を反転させた値を返します。
/// 結果の値が型の上限より大きい場合はエラーを返します。
pub fn negation(T: type, value: T) OverflowError!T {
    assert(isSignedInteger(T));

    if (value == min(T)) {
        return OverflowError.IntegerOverflow;
    }

    return -%value;
}

/// 整数型の符号を反転させた値を返します。
/// 結果の値が型の上限より大きい場合は剰余の値を返します。
pub fn negationWrapping(T: type, value: T) T {
    assert(isSignedInteger(T));

    return -%value;
}

/// 整数型の符号を反転させた値を返します。
/// 結果の値が型の上限より大きい場合は剰余の値を返します。
pub fn negationExtend(T: type, value: T) Extend(T, 1) {
    assert(isSignedInteger(T));

    return -%@as(Extend(T, 1), value);
}

/// 整数型の符号を反転させた値を返します。
/// 結果の値が型の上限より大きい場合は未定義動作になります。
pub fn negationUnsafe(T: type, value: T) T {
    assert(isSignedInteger(T));

    return -value;
}

test "符号反転 符号あり" {
    const num: i8 = 1;

    try expectEqual(-num, -1);
    try expectEqual(-%num, -1);

    try expectEqual(negation(i8, num), -1);
    try expectEqual(negationWrapping(i8, num), -1);
    try expectEqualWithType(i9, negationExtend(i8, num), -1);
    try expectEqual(negationUnsafe(i8, num), -1);
}

test "符号反転 符号あり オーバーフロー" {
    const num: i8 = -0x80;

    // try expectEqual(-num, 0x80); // build error: overflow of integer type 'i8' with value '128'
    try expectEqual(-%num, -0x80);

    try expectEqual(negation(i8, num), error.IntegerOverflow);
    try expectEqual(negationWrapping(i8, num), -0x80);
    try expectEqualWithType(i9, negationExtend(i8, num), 0x80);
    // try expectEqual(negationUnsafe(i8, num), -0x80); // panic: integer overflow
}

// 足し算

/// 二つの整数を足した結果を返します。
/// 結果の値が型の上限より大きい場合はエラーを返します。
pub fn add(T: type, left: T, right: T) OverflowError!T {
    const result, const carry = @addWithOverflow(left, right);
    if (carry == 1) {
        return OverflowError.IntegerOverflow;
    }

    return result;
}

/// 二つの整数を足した結果を返します。
/// 結果の値が型の上限より大きい場合は剰余の値を返します。
pub fn addWrapping(T: type, left: T, right: T) T {
    return left +% right;
}

/// 二つの整数を足した結果を返します。
/// 結果の値が値が型の上限より大きい場合は最大値・最小値に制限されます。
pub fn addSaturation(T: type, left: T, right: T) T {
    return left +| right;
}

/// 二つの整数を足した結果を返します。
/// 結果の値が値が型の上限より大きい場合はタプルの2番目の値に1を返します。
pub fn addOverflow(T: type, left: T, right: T) struct { T, u1 } {
    const result, const carry = @addWithOverflow(left, right);

    return .{ result, carry };
}

/// 二つの整数を足した結果を返します。
/// すべての結果の値が収まるように結果の型を拡張します。
pub fn addExtend(T: type, left: T, right: T) Extend(T, 1) {
    return @as(Extend(T, 1), left) + right;
}

/// 二つの整数を足した結果を返します。
/// 結果の値が値が型の上限より大きい場合は未定義動作になります。
pub fn addUnsafe(T: type, left: T, right: T) T {
    return left + right;
}

test "足し算 符号なし" {
    const left: u8 = 2;
    const right: u8 = 2;

    try expectEqual(left + right, 4);
    try expectEqual(left +% right, 4);
    try expectEqual(left +| right, 4);
    try expectEqual(@addWithOverflow(left, right), .{ 4, 0 });

    try expectEqual(add(u8, left, right), 4);
    try expectEqual(addWrapping(u8, left, right), 4);
    try expectEqual(addSaturation(u8, left, right), 4);
    try expectEqual(addOverflow(u8, left, right), .{ 4, 0 });
    try expectEqualWithType(u9, addExtend(u8, left, right), 4);
    try expectEqual(addUnsafe(u8, left, right), 4);
}

test "足し算 符号なし 上にオーバーフロー" {
    const left: u8 = 0xff;
    const right: u8 = 1;

    // try expectEqual(left + right, 0x100); // build error: overflow of integer type 'u8' with value '256'
    try expectEqual(left +% right, 0);
    try expectEqual(left +| right, 0xff);
    try expectEqual(@addWithOverflow(left, right)[0], 0);
    try expectEqual(@addWithOverflow(left, right)[1], 1);

    try expectEqual(add(u8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(addWrapping(u8, left, right), 0);
    try expectEqual(addSaturation(u8, left, right), 0xff);
    try expectEqual(addOverflow(u8, left, right), .{ 0, 1 });
    try expectEqualWithType(u9, addExtend(u8, left, right), 0x100);
    // try expectEqual(addUnsafe(u8, left, right), 0); // panic: integer overflow
}

test "足し算 符号あり" {
    const left: i8 = 2;
    const right: i8 = 2;

    try expectEqual(left + right, 4);
    try expectEqual(left +% right, 4);
    try expectEqual(left +| right, 4);
    try expectEqual(@addWithOverflow(left, right)[0], 4);
    try expectEqual(@addWithOverflow(left, right)[1], 0);

    try expectEqual(add(i8, left, right), 4);
    try expectEqual(addWrapping(i8, left, right), 4);
    try expectEqual(addSaturation(i8, left, right), 4);
    try expectEqual(addOverflow(i8, left, right), .{ 4, 0 });
    try expectEqualWithType(i9, addExtend(i8, left, right), 4);
    try expectEqual(addUnsafe(i8, left, right), 4);
}

test "足し算 符号あり 上にオーバーフロー" {
    const left: i8 = 0x7f;
    const right: i8 = 1;

    // try expectEqual(left + right, 0x80); // build error: overflow of integer type 'i8' with value '128'
    try expectEqual(left +% right, -0x80);
    try expectEqual(left +| right, 0x7f);
    try expectEqual(@addWithOverflow(left, right)[0], -0x80);
    try expectEqual(@addWithOverflow(left, right)[1], 1);

    try expectEqual(add(i8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(addWrapping(i8, left, right), -0x80);
    try expectEqual(addSaturation(i8, left, right), 0x7f);
    try expectEqual(addOverflow(i8, left, right), .{ -0x80, 1 });
    try expectEqualWithType(i9, addExtend(i8, left, right), 0x80);
    // try expectEqual(addUnsafe(i8, left, right), 0); // panic: integer overflow
}

test "足し算 符号あり 下にオーバーフロー" {
    const left: i8 = -0x80;
    const right: i8 = -1;

    // try expectEqual(left + right, -0x81); // build error: overflow of integer type 'i8' with value '-129'
    try expectEqual(left +% right, 0x7f);
    try expectEqual(left +| right, -0x80);
    try expectEqual(@addWithOverflow(left, right)[0], 0x7f);
    try expectEqual(@addWithOverflow(left, right)[1], 1);

    try expectEqual(add(i8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(addWrapping(i8, left, right), 0x7f);
    try expectEqual(addSaturation(i8, left, right), -0x80);
    try expectEqual(addOverflow(i8, left, right), .{ 0x7f, 1 });
    try expectEqualWithType(i9, addExtend(i8, left, right), -0x81);
    // try expectEqual(addUnsafe(i8, left, right), 0); // panic: integer overflow
}

test "足し算 extend すべての値が範囲内になる" {
    try expectEqualWithType(u9, addExtend(u8, 0xff, 0xff), 0x1fe);
    try expectEqualWithType(u9, addExtend(u8, 0, 0), 0);

    try expectEqualWithType(i9, addExtend(i8, 0x7f, 0x7f), 0xfe);
    try expectEqualWithType(i9, addExtend(i8, -0x80, -0x80), -0x100);
}

// 引き算

/// 二つの整数を左から右を引いた結果を返します。
/// 結果の値が型の上限より大きい場合はエラーを返します。
pub fn sub(T: type, left: T, right: T) OverflowError!T {
    const result, const carry = @subWithOverflow(left, right);
    if (carry == 1) {
        return OverflowError.IntegerOverflow;
    }

    return result;
}

/// 二つの整数を左から右を引いた結果を返します。
/// 結果の値が型の上限より大きい場合は剰余の値を返します。
pub fn subWrapping(T: type, left: T, right: T) T {
    return left -% right;
}

/// 二つの整数を左から右を引いた結果を返します。
/// 結果の値が値が型の上限より大きい場合は最大値・最小値に制限されます。
pub fn subSaturation(T: type, left: T, right: T) T {
    return left -| right;
}

/// 二つの整数を左から右を引いた結果を返します。
/// 結果の値が値が型の上限より大きい場合はタプルの2番目の値に1を返します。
pub fn subOverflow(T: type, left: T, right: T) struct { T, u1 } {
    const result, const carry = @subWithOverflow(left, right);

    return .{ result, carry };
}

/// 二つの整数を左から右を引いた結果を返します。
/// すべての結果の値が収まるように結果の型を拡張します。
pub fn subExtend(T: type, left: T, right: T) Signed(Extend(T, 1)) {
    return @as(Signed(Extend(T, 1)), left) - right;
}

/// 二つの整数を左から右を引いた結果を返します。
/// 結果の値が値が型の上限より大きい場合は未定義動作になります。
pub fn subUnsafe(T: type, left: T, right: T) T {
    return left - right;
}

test "引き算 符号なし" {
    const left: u8 = 5;
    const right: u8 = 3;

    try expectEqual(left - right, 2);
    try expectEqual(left -% right, 2);
    try expectEqual(left -| right, 2);
    try expectEqual(@subWithOverflow(left, right)[0], 2);
    try expectEqual(@subWithOverflow(left, right)[1], 0);

    try expectEqual(sub(u8, left, right), 2);
    try expectEqual(subWrapping(u8, left, right), 2);
    try expectEqual(subSaturation(u8, left, right), 2);
    try expectEqual(subOverflow(u8, left, right), .{ 2, 0 });
    try expectEqualWithType(i9, subExtend(u8, left, right), 2);
    try expectEqual(subUnsafe(u8, left, right), 2);
}

test "引き算 符号なし 下にオーバーフロー" {
    const left: u8 = 3;
    const right: u8 = 5;

    // try expectEqual(left - right, -2); // build error: overflow of integer type 'u8' with value '-2'
    try expectEqual(left -% right, 0xfe);
    try expectEqual(left -| right, 0);
    try expectEqual(@subWithOverflow(left, right)[0], 0xfe);
    try expectEqual(@subWithOverflow(left, right)[1], 1);

    try expectEqual(sub(u8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(subWrapping(u8, left, right), 0xfe);
    try expectEqual(subSaturation(u8, left, right), 0);
    try expectEqual(subOverflow(u8, left, right), .{ 0xfe, 1 });
    try expectEqualWithType(i9, subExtend(u8, left, right), -2);
    // try expectEqual(subUnsafe(u8, left, right), 0); // panic: integer overflow
}

test "引き算 符号あり" {
    const left: i8 = 3;
    const right: i8 = 5;

    try expectEqual(left - right, -2);
    try expectEqual(left -% right, -2);
    try expectEqual(left -| right, -2);
    try expectEqual(@subWithOverflow(left, right)[0], -2);
    try expectEqual(@subWithOverflow(left, right)[1], 0);

    try expectEqual(sub(i8, left, right), -2);
    try expectEqual(subWrapping(i8, left, right), -2);
    try expectEqual(subSaturation(i8, left, right), -2);
    try expectEqual(subOverflow(i8, left, right), .{ -2, 0 });
    try expectEqualWithType(i9, subExtend(i8, left, right), -2);
    try expectEqual(subUnsafe(i8, left, right), -2);
}

test "引き算 符号あり 上にオーバーフロー" {
    const left: i8 = 0x7f;
    const right: i8 = -1;

    // try expectEqual(left - right, 0x80); // build error: overflow of integer type 'i8' with value '128'
    try expectEqual(left -% right, -0x80);
    try expectEqual(left -| right, 0x7f);
    try expectEqual(@subWithOverflow(left, right)[0], -0x80);
    try expectEqual(@subWithOverflow(left, right)[1], 1);

    try expectEqual(sub(i8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(subWrapping(i8, left, right), -0x80);
    try expectEqual(subSaturation(i8, left, right), 0x7f);
    try expectEqual(subOverflow(i8, left, right), .{ -0x80, 1 });
    try expectEqualWithType(i9, subExtend(i8, left, right), 0x80);
    // try expectEqual(subUnsafe(i8, left, right), 0); // panic: integer overflow
}

test "引き算 符号あり 下にオーバーフロー" {
    const left: i8 = -0x80;
    const right: i8 = 1;

    // try expectEqual(left - right, -0x81); // build error: overflow of integer type 'i8' with value '-129'
    try expectEqual(left -% right, 0x7f);
    try expectEqual(left -| right, -0x80);
    try expectEqual(@subWithOverflow(left, right)[0], 0x7f);
    try expectEqual(@subWithOverflow(left, right)[1], 1);

    try expectEqual(sub(i8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(subWrapping(i8, left, right), 0x7f);
    try expectEqual(subSaturation(i8, left, right), -0x80);
    try expectEqual(subOverflow(i8, left, right), .{ 0x7f, 1 });
    try expectEqualWithType(i9, subExtend(i8, left, right), -0x81);
    // try expectEqual(subUnsafe(i8, left, right), 0); // panic: integer overflow
}

test "引き算 extend すべての値が範囲内になる" {
    try expectEqualWithType(i9, subExtend(u8, 0, 0xff), -0xff);
    try expectEqualWithType(i9, subExtend(u8, 0xff, 0), 0xff);

    try expectEqualWithType(i9, subExtend(i8, 0x7f, -0x80), 0xff);
    try expectEqualWithType(i9, subExtend(i8, -0x80, 0x7f), -0xff);
}

// 掛け算

/// 二つの整数を掛けた結果を返します。
/// 結果の値が型の上限より大きい場合はエラーを返します。
pub fn mul(T: type, left: T, right: T) OverflowError!T {
    const result, const carry = @mulWithOverflow(left, right);
    if (carry == 1) {
        return OverflowError.IntegerOverflow;
    }

    return result;
}

/// 二つの整数を掛けた結果を返します。
/// 結果の値が型の上限より大きい場合は剰余の値を返します。
pub fn mulWrapping(T: type, left: T, right: T) T {
    return left *% right;
}

/// 二つの整数を掛けた結果を返します。
/// 結果の値が値が型の上限より大きい場合は最大値・最小値に制限されます。
pub fn mulSaturation(T: type, left: T, right: T) T {
    return left *| right;
}

/// 二つの整数を掛けた結果を返します。
/// 結果の値が値が型の上限より大きい場合はタプルの2番目の値に1を返します。
pub fn mulOverflow(T: type, left: T, right: T) struct { T, u1 } {
    const result, const carry = @mulWithOverflow(left, right);

    return .{ result, carry };
}

/// 二つの整数を掛けた結果を返します。
/// すべての結果の値が収まるように結果の型を拡張します。
pub fn mulExtend(T: type, left: T, right: T) Extend(T, sizeOf(T)) {
    return @as(Extend(T, sizeOf(T)), left) * right;
}

/// 二つの整数を掛けた結果を返します。
/// 結果の値が値が型の上限より大きい場合は未定義動作になります。
pub fn mulUnsafe(T: type, left: T, right: T) T {
    return left * right;
}

test "掛け算 符号なし" {
    const left: u8 = 4;
    const right: u8 = 3;

    try expectEqual(left * right, 12);
    try expectEqual(left *% right, 12);
    try expectEqual(left *| right, 12);
    try expectEqual(@mulWithOverflow(left, right)[0], 12);
    try expectEqual(@mulWithOverflow(left, right)[1], 0);

    try expectEqual(mul(u8, left, right), 12);
    try expectEqual(mulWrapping(u8, left, right), 12);
    try expectEqual(mulSaturation(u8, left, right), 12);
    try expectEqual(mulOverflow(u8, left, right), .{ 12, 0 });
    try expectEqualWithType(u16, mulExtend(u8, left, right), 12);
    try expectEqual(mulUnsafe(u8, left, right), 12);
}

test "掛け算 符号なし 上にオーバーフロー" {
    const left: u8 = 0x10;
    const right: u8 = 0x10;

    // try expectEqual(left * right, 0x100); // build error: overflow of integer type 'u8' with value '256'
    try expectEqual(left *% right, 0);
    try expectEqual(left *| right, 0xff);
    try expectEqual(@mulWithOverflow(left, right)[0], 0);
    try expectEqual(@mulWithOverflow(left, right)[1], 1);

    try expectEqual(mul(u8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(mulWrapping(u8, left, right), 0);
    try expectEqual(mulSaturation(u8, left, right), 0xff);
    try expectEqual(mulOverflow(u8, left, right), .{ 0, 1 });
    try expectEqualWithType(u16, mulExtend(u8, left, right), 0x100);
    // try expectEqual(mulUnsafe(u8, left, right), 0); // panic: integer overflow
}

test "掛け算 符号あり" {
    const left: i8 = -2;
    const right: i8 = 4;

    try expectEqual(left * right, -8);
    try expectEqual(left *% right, -8);
    try expectEqual(left *| right, -8);
    try expectEqual(@mulWithOverflow(left, right)[0], -8);
    try expectEqual(@mulWithOverflow(left, right)[1], 0);

    try expectEqual(mul(i8, left, right), -8);
    try expectEqual(mulWrapping(i8, left, right), -8);
    try expectEqual(mulSaturation(i8, left, right), -8);
    try expectEqual(mulOverflow(i8, left, right), .{ -8, 0 });
    try expectEqualWithType(i16, mulExtend(i8, left, right), -8);
    try expectEqual(mulUnsafe(i8, left, right), -8);
}

test "掛け算 符号あり 上にオーバーフロー" {
    const left: i8 = 0x40;
    const right: i8 = 2;

    // try expectEqual(left * right, 0x80); // build error: overflow of integer type 'i8' with value '128'
    try expectEqual(left *% right, -0x80);
    try expectEqual(left *| right, 0x7f);
    try expectEqual(@mulWithOverflow(left, right)[0], -0x80);
    try expectEqual(@mulWithOverflow(left, right)[1], 1);

    try expectEqual(mul(i8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(mulWrapping(i8, left, right), -0x80);
    try expectEqual(mulSaturation(i8, left, right), 0x7f);
    try expectEqual(mulOverflow(i8, left, right), .{ -0x80, 1 });
    try expectEqualWithType(i16, mulExtend(i8, left, right), 0x80);
    // try expectEqual(mulUnsafe(i8, left, right), 0); // panic: integer overflow
}

test "掛け算 符号あり 下にオーバーフロー" {
    const left: i8 = -0x80;
    const right: i8 = 2;

    // try expectEqual(left * right, -0x100); // build error: overflow of integer type 'i8' with value '-256'
    try expectEqual(left *% right, 0);
    try expectEqual(left *| right, -0x80);
    try expectEqual(@mulWithOverflow(left, right)[0], 0);
    try expectEqual(@mulWithOverflow(left, right)[1], 1);

    try expectEqual(mul(i8, left, right), OverflowError.IntegerOverflow);
    try expectEqual(mulWrapping(i8, left, right), 0);
    try expectEqual(mulSaturation(i8, left, right), -0x80);
    try expectEqual(mulOverflow(i8, left, right), .{ 0, 1 });
    try expectEqualWithType(i16, mulExtend(i8, left, right), -0x100);
    // try expectEqual(mulUnsafe(i8, left, right), 0); // panic: integer overflow
}

test "割り算 符号なし 余りなし" {
    const left: u8 = 6;
    const right: u8 = 3;

    try expectEqual(left / right, 2);
    try expectEqual(@divTrunc(left, right), 2);
    try expectEqual(@divFloor(left, right), 2);
    try expectEqual(@divExact(left, right), 2);
}

test "割り算 符号なし 余りあり" {
    const left: u8 = 7;
    const right: u8 = 3;

    try expectEqual(left / right, 2);
    try expectEqual(@divTrunc(left, right), 2);
    try expectEqual(@divFloor(left, right), 2);
    // try expectEqual(@divExact(left, right), 2); // build error: exact division produced remainder
}

test "割り算 符号なし ゼロ除算" {
    // const left: u8 = 6;
    // const right: u8 = 0;

    // try expectEqual(left /  right, 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@divTrunc(left, right), 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@divFloor(left, right), 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@divExact(left, right), 2); // build error: division by zero here causes undefined behavior
}

test "割り算 符号あり" {
    const left: i8 = 6;
    const right: i8 = 3;

    try expectEqual(left / right, 2);
    try expectEqual(@divTrunc(left, right), 2);
    try expectEqual(@divFloor(left, right), 2);
    try expectEqual(@divExact(left, right), 2);
}

test "割り算 符号あり オーバーフロー" {
    // const left: i8 = -0x80;
    // const right: i8 = -1;

    // try expectEqual(left / right, 0x80); // build error: overflow of integer type 'i8' with value '128'
    // try expectEqual(@divTrunc(left, right), 0x80); // build error: overflow of integer type 'i8' with value '128'
    // try expectEqual(@divFloor(left, right), 0x80); // build error: type 'i8' cannot represent integer value '128'
    // try expectEqual(@divExact(left, right), 0x80); // build error: overflow of integer type 'i8' with value '128'
}

test "割り算 符号あり 余りあり 正÷正" {
    const left: i8 = 7;
    const right: i8 = 3;

    try expectEqual(left / right, 2);
    try expectEqual(@divTrunc(left, right), 2);
    try expectEqual(@divFloor(left, right), 2);
    // try expectEqual(@divExact(left, right), 2); // build error: exact division produced remainder
}

test "割り算 符号あり 余りあり 正÷負" {
    const left: i8 = 7;
    const right: i8 = -3;

    try expectEqual(left / right, -2);
    try expectEqual(@divTrunc(left, right), -2);
    try expectEqual(@divFloor(left, right), -3);
    // try expectEqual(@divExact(left, right), 2); // build error: exact division produced remainder
}

test "割り算 符号あり 余りあり 負÷正" {
    const left: i8 = -7;
    const right: i8 = 3;

    try expectEqual(left / right, -2);
    try expectEqual(@divTrunc(left, right), -2);
    try expectEqual(@divFloor(left, right), -3);
    // try expectEqual(@divExact(left, right), 2); // build error: exact division produced remainder
}

test "割り算 符号あり 余りあり 負÷負" {
    const left: i8 = -7;
    const right: i8 = -3;

    try expectEqual(left / right, 2);
    try expectEqual(@divTrunc(left, right), 2);
    try expectEqual(@divFloor(left, right), 2);
    // try expectEqual(@divExact(left, right), 2); // build error: exact division produced remainder
}

test "割り算 符号あり ゼロ除算" {
    // const left: i8 = -6;
    // const right: i8 = 0;

    // try expectEqual(left / right, 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@divTrunc(left, right), 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@divFloor(left, right), 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@divExact(left, right), 2); // build error: division by zero here causes undefined behavior
}

test "余り算 符号なし" {
    const left: u8 = 8;
    const right: u8 = 3;

    try expectEqual(left % right, 2);
    try expectEqual(@rem(left, right), 2);
    try expectEqual(@mod(left, right), 2);
}

test "余り算 符号なし ゼロ除算" {
    // const left: u8 = 8;
    // const right: u8 = 0;

    // try expectEqual(left % right, 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@rem(left, right), 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@mod(left, right), 2); // build error: division by zero here causes undefined behavior
}

test "余り算 符号あり 正÷正" {
    const left: i8 = 8;
    const right: i8 = 3;

    try expectEqual(left % right, 2);
    try expectEqual(@rem(left, right), 2);
    try expectEqual(@mod(left, right), 2);
}

test "余り算 符号あり 正÷負" {
    const left: i8 = 8;
    const right: i8 = -3;

    // try expectEqual(left % right, 2); // build error: remainder division with 'i8' and 'i8': signed integers and floats must use @rem or @mod
    try expectEqual(@rem(left, right), 2);
    try expectEqual(@mod(left, right), -1);
}

test "余り算 符号あり 負÷正" {
    const left: i8 = -8;
    const right: i8 = 3;

    // try expectEqual(left % right, 2); // build error: remainder division with 'i8' and 'i8': signed integers and floats must use @rem or @mod
    try expectEqual(@rem(left, right), -2);
    try expectEqual(@mod(left, right), 1);
}

test "余り算 符号あり 負÷負" {
    const left: i8 = -8;
    const right: i8 = -3;

    // try expectEqual(left % right, 2); // build error: remainder division with 'i8' and 'i8': signed integers and floats must use @rem or @mod
    try expectEqual(@rem(left, right), -2);
    try expectEqual(@mod(left, right), -2);
}

test "余り算 符号あり ゼロ除算" {
    // const left: i8 = 8;
    // const right: i8 = 0;

    // try expectEqual(left % right, 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@rem(left, right), 2); // build error: division by zero here causes undefined behavior
    // try expectEqual(@mod(left, right), 2); // build error: division by zero here causes undefined behavior
}

test "左ビットシフト 符号なし" {
    const left: u8 = 0b00000111;
    const right: u3 = 3;

    try expectEqual(left << right, 0b00111000);
    try expectEqual(left <<| right, 0b00111000);
    try expectEqual(@shlExact(left, right), 0b00111000);
    try expectEqual(@shlWithOverflow(left, right), .{ 0b00111000, 0 });
}

test "左ビットシフト 符号なし オーバーフロー" {
    const left: u8 = 0b00000111;
    const right: u3 = 6;

    try expectEqual(left << right, 0b11000000);
    try expectEqual(left <<| right, 0b11111111);
    // try expectEqual(@shlExact(left, right), 0b1_11000000); // build error: operation caused overflow
    try expectEqual(@shlWithOverflow(left, right), .{ 0b11000000, 1 });
}

test "左ビットシフト 符号あり 正の数" {
    const left: i8 = asSigned(u8, 0b00000111);
    const right: u3 = 3;

    try expectEqual(left << right, asSigned(u8, 0b00111000));
    try expectEqual(left <<| right, asSigned(u8, 0b00111000));
    try expectEqual(@shlExact(left, right), asSigned(u8, 0b00111000));
    try expectEqual(@shlWithOverflow(left, right), .{ asSigned(u8, 0b00111000), 0 });
}

test "左ビットシフト 符号あり 負の数" {
    const left: i8 = asSigned(u8, 0b11111001);
    const right: u3 = 3;

    try expectEqual(left << right, asSigned(u8, 0b11001000));
    try expectEqual(left <<| right, asSigned(u8, 0b11001000));
    try expectEqual(@shlExact(left, right), asSigned(u8, 0b11001000));
    try expectEqual(@shlWithOverflow(left, right), .{ asSigned(u8, 0b11001000), 0 });
}

test "左ビットシフト 符号あり 正の数 オーバーフロー" {
    const left: i8 = asSigned(u8, 0b00000111);
    const right: u3 = 6;

    try expectEqual(left << right, asSigned(u8, 0b11000000));
    try expectEqual(left <<| right, asSigned(u8, 0b01111111));
    // try expectEqual(@shlExact(left, right), asSigned(u8, 0b1_11000000)); // build error: type 'u8' cannot represent integer value '448'
    try expectEqual(@shlWithOverflow(left, right), .{ asSigned(u8, 0b11000000), 1 });
}

test "左ビットシフト 符号あり 負の数 オーバーフロー" {
    const left: i8 = asSigned(u8, 0b11111001);
    const right: u3 = 6;

    try expectEqual(left << right, asSigned(u8, 0b01000000));
    try expectEqual(left <<| right, asSigned(u8, 0b10000000));
    // try expectEqual(@shlExact(left, right), asSigned(u8, 0b111110_01000000)); // build error: type 'u8' cannot represent integer value '15936'
    try expectEqual(@shlWithOverflow(left, right), .{ asSigned(u8, 0b01000000), 1 });
}

test "右ビットシフト 符号なし" {
    const left: u8 = 0b10111000;
    const right: u3 = 3;

    try expectEqual(left >> right, 0b00010111);
    try expectEqual(@shrExact(left, right), 0b00010111);
}

test "右ビットシフト 符号なし オーバーフロー" {
    const left: u8 = 0b10111000;
    const right: u3 = 6;

    try expectEqual(left >> right, 0b00000010);
    // try expectEqual(@shrExact(left, right), 0b00000010); // build error: exact shift shifted out 1 bits
}

test "右ビットシフト 符号あり 正の数" {
    const left: i8 = asSigned(u8, 0b10111000);
    const right: u3 = 3;

    try expectEqual(left >> right, asSigned(u8, 0b11110111));
    try expectEqual(@shrExact(left, right), asSigned(u8, 0b11110111));
}
