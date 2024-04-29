//! (lib.primitive.integer)
//! 整数型の操作する関数を与えます。
//! 整数型に含まれる型は以下にリストされます。
//!
//! - ビットサイズの指定された符号付き整数型 (`i0`から`i65535`)
//! - ビットサイズの指定された符号なし整数型 (`u0`から`u65535`)
//! - ポインタサイズの符号付き整数型 (`isize`)
//! - ポインタサイズの符号なし整数型 (`usize`)
//! - コンパイル時整数型 (`comptime_int`)
//!
//! 符号付き整数型は2の補数表現で表されます。

const std = @import("std");
const lib = @import("../lib.zig");
const assert = lib.testing.assert;

/// このデータ構造は Zig 言語コード生成で使用されるため、コンパイラー実装と同期を保つ必要があります。
pub const Signedness = std.builtin.Signedness;

const OverflowError = error{IntegerOverflow};
const DivZeroError = error{DivideByZero};

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
pub fn Signed(comptime T: type) type {
    return Integer(.signed, sizeOf(T));
}

/// 整数型を受け取り、同じビット数の符号なし整数を返します。
pub fn Unsigned(comptime T: type) type {
    return Integer(.unsigned, sizeOf(T));
}

test "符号とビットサイズから整数型を作成する" {
    const expect = lib.testing.expect;

    const IntType: type = Integer(.signed, 16);
    try expect(IntType == i16);
}

// 整数型の種類を調べる関数

/// 型が符号付き整数型かどうかを判定します。
///
/// 符号付き整数型(`i0`から`i65535`、 または`isize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isSignedInteger(comptime T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => |i| i.signedness == .signed,
        else => false,
    };
}

/// 型が符号なし整数型かどうかを判定します。
///
/// 符号なし整数型(`u0`から`u65535`、 または`usize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isUnsignedInteger(comptime T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => |i| i.signedness == .unsigned,
        else => false,
    };
}

/// 型がビットサイズの整数型かどうかを判定します。
///
/// ビットサイズの指定された整数型(`i0`から`i65535`、 または`u0`から`u65535`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isBitSizedInteger(comptime T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => T != usize and T != isize,
        else => false,
    };
}

/// 型がポインタサイズの整数型かどうかを判定します。
///
/// ポインタサイズの整数型(`isize`、 または`usize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isPointerSizedInteger(comptime T: type) bool {
    return T == usize or T == isize;
}

/// 型がコンパイル時整数(`comptime_int`)かどうかを判定します。
pub fn isComptimeInteger(comptime T: type) bool {
    const info = @typeInfo(T);

    return info == .ComptimeInt;
}

/// 型が整数かどうかを判定します。
pub fn isInteger(comptime T: type) bool {
    const info = @typeInfo(T);
    return info == .Int or info == .ComptimeInt;
}

pub fn signOf(comptime T: type) Signedness {
    assert(isInteger(T));

    return @typeInfo(T).Int.signedness;
}

/// 型のビットサイズを調べます。
pub fn sizeOf(comptime T: type) u16 {
    assert(isInteger(T));

    return @typeInfo(T).Int.bits;
}

test "整数型の型を調べる関数" {
    const expect = lib.testing.expect;

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
pub fn max(comptime T: type) T {
    return switch (comptime signOf(T)) {
        .unsigned => ~@as(T, 0),
        .signed => ~@as(Unsigned(T), 0) >> 1,
    };
}

/// 与えられた整数型の表現できる最小の整数を返します。
pub fn min(comptime T: type) T {
    return switch (comptime signOf(T)) {
        .unsigned => 0,
        .signed => ~max(T),
    };
}

test "整数型の最大値と最小値" {
    const expect = lib.testing.expectEqual;

    try expect(max(u8), 0xff);
    try expect(min(u8), 0);

    try expect(max(i8), 0x7f);
    try expect(min(i8), -0x80);
}

test "整数型の符号反転 符号あり" {
    const expect = lib.testing.expectEqual;

    const num: i8 = 1;

    try expect(-num, -1);
    try expect(-%num, -1);
}

test "整数型の符号反転 符号あり オーバーフロー" {
    const expect = lib.testing.expectEqual;

    const num: i8 = -0x80;

    // try expect(-num, 0x80); // build error
    try expect(-%num, -0x80);
}

test "整数型の足し算 符号なし" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 2;
    const right: u8 = 2;

    try expect(left + right, 4);
    try expect(left +% right, 4);
    try expect(left +| right, 4);
    try expect(@addWithOverflow(left, right)[0], 4);
    try expect(@addWithOverflow(left, right)[1], 0);
}

test "整数型の足し算 符号なし 上にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 0xff;
    const right: u8 = 1;

    // try expect(left + right, 0x100); // build error
    try expect(left +% right, 0);
    try expect(left +| right, 255);
    try expect(@addWithOverflow(left, right)[0], 0);
    try expect(@addWithOverflow(left, right)[1], 1);
}

test "整数型の足し算 符号あり" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 2;
    const right: i8 = 2;

    try expect(left + right, 4);
    try expect(left +% right, 4);
    try expect(left +| right, 4);
    try expect(@addWithOverflow(left, right)[0], 4);
    try expect(@addWithOverflow(left, right)[1], 0);
}

test "整数型の足し算 符号あり 上にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 0x7f;
    const right: i8 = 1;

    // try expect(left + right, 0x80); // build error
    try expect(left +% right, -0x80);
    try expect(left +| right, 0x7f);
    try expect(@addWithOverflow(left, right)[0], -0x80);
    try expect(@addWithOverflow(left, right)[1], 1);
}

test "整数型の足し算 符号あり 下にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: i8 = -0x80;
    const right: i8 = -1;

    // try expect(left + right, -0x81); // build error
    try expect(left +% right, 0x7f);
    try expect(left +| right, -0x80);
    try expect(@addWithOverflow(left, right)[0], 0x7f);
    try expect(@addWithOverflow(left, right)[1], 1);
}

test "整数型の引き算 符号なし" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 5;
    const right: u8 = 3;

    try expect(left - right, 2);
    try expect(left -% right, 2);
    try expect(left -| right, 2);
    try expect(@subWithOverflow(left, right)[0], 2);
    try expect(@subWithOverflow(left, right)[1], 0);
}

test "整数型の引き算 符号なし 下にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 3;
    const right: u8 = 5;

    // try expect(left - right, -2); // build error
    try expect(left -% right, 0xfe);
    try expect(left -| right, 0);
    try expect(@subWithOverflow(left, right)[0], 0xfe);
    try expect(@subWithOverflow(left, right)[1], 1);
}

test "整数型の引き算 符号あり" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 3;
    const right: i8 = 5;

    try expect(left - right, -2);
    try expect(left -% right, -2);
    try expect(left -| right, -2);
    try expect(@subWithOverflow(left, right)[0], -2);
    try expect(@subWithOverflow(left, right)[1], 0);
}

test "整数型の引き算 符号あり 上にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 0x7f;
    const right: i8 = -1;

    // try expect(left - right, 0x80); // build error
    try expect(left -% right, -0x80);
    try expect(left -| right, 0x7f);
    try expect(@subWithOverflow(left, right)[0], -0x80);
    try expect(@subWithOverflow(left, right)[1], 1);
}

test "整数型の引き算 符号あり 下にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: i8 = -0x80;
    const right: i8 = 1;

    // try expect(left - right, -0x81); // build error
    try expect(left -% right, 0x7f);
    try expect(left -| right, -0x80);
    try expect(@subWithOverflow(left, right)[0], 0x7f);
    try expect(@subWithOverflow(left, right)[1], 1);
}

test "整数型の掛け算 符号なし" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 4;
    const right: u8 = 3;

    try expect(left * right, 12);
    try expect(left *% right, 12);
    try expect(left *| right, 12);
    try expect(@mulWithOverflow(left, right)[0], 12);
    try expect(@mulWithOverflow(left, right)[1], 0);
}

test "整数型の掛け算 符号なし 上にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 0x10;
    const right: u8 = 0x10;

    // try expect(left * right, 0x100); // build error
    try expect(left *% right, 0);
    try expect(left *| right, 0xff);
    try expect(@mulWithOverflow(left, right)[0], 0);
    try expect(@mulWithOverflow(left, right)[1], 1);
}

test "整数型の掛け算 符号あり" {
    const expect = lib.testing.expectEqual;

    const left: i8 = -2;
    const right: i8 = 4;

    try expect(left * right, -8);
    try expect(left *% right, -8);
    try expect(left *| right, -8);
    try expect(@mulWithOverflow(left, right)[0], -8);
    try expect(@mulWithOverflow(left, right)[1], 0);
}

test "整数型の掛け算 符号あり 上にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 0x40;
    const right: i8 = 2;

    // try expect(left * right, 0x80); // build error
    try expect(left *% right, -0x80);
    try expect(left *| right, 0x7f);
    try expect(@mulWithOverflow(left, right)[0], -0x80);
    try expect(@mulWithOverflow(left, right)[1], 1);
}

test "整数型の掛け算 符号あり 下にオーバーフロー" {
    const expect = lib.testing.expectEqual;

    const left: i8 = -0x80;
    const right: i8 = 2;

    // try expect(left * right, -0x100); // build error
    try expect(left *% right, 0);
    try expect(left *| right, -0x80);
    try expect(@mulWithOverflow(left, right)[0], 0);
    try expect(@mulWithOverflow(left, right)[1], 1);
}

test "整数型の割り算 符号なし 余りなし" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 6;
    const right: u8 = 3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    try expect(@divExact(left, right), 2);
}

test "整数型の割り算 符号なし 余りあり" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 7;
    const right: u8 = 3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    // try expect(@divExact(left, right), 2); // build error
}

test "整数型の割り算 符号なし ゼロ除算" {
    // const expect = lib.testing.expectEqual;

    // const left: u8 = 6;
    // const right: u8 = 0;

    // try expect(left / right, 2); // build error
    // try expect(@divTrunc(left, right), 2); // build error
    // try expect(@divFloor(left, right), 2); // build error
    // try expect(@divExact(left, right), 2); // build error
}

test "整数型の割り算 符号あり" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 6;
    const right: i8 = 3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    try expect(@divExact(left, right), 2);
}

test "整数型の割り算 符号あり オーバーフロー" {
    // const expect = lib.testing.expectEqual;

    // const left: i8 = -0x80;
    // const right: i8 = -1;

    // try expect(left / right, 0x80); // build error
    // try expect(@divTrunc(left, right), 0x80); // build error
    // try expect(@divFloor(left, right), 0x80); // build error
    // try expect(@divExact(left, right), 0x80); // build error
}

test "整数型の割り算 符号あり 余りあり 正÷正" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 7;
    const right: i8 = 3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    // try expect(@divExact(left, right), 2); // build error
}

test "整数型の割り算 符号あり 余りあり 正÷負" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 7;
    const right: i8 = -3;

    try expect(left / right, -2);
    try expect(@divTrunc(left, right), -2);
    try expect(@divFloor(left, right), -3);
    // try expect(@divExact(left, right), 2); // build error
}

test "整数型の割り算 符号あり 余りあり 負÷正" {
    const expect = lib.testing.expectEqual;

    const left: i8 = -7;
    const right: i8 = 3;

    try expect(left / right, -2);
    try expect(@divTrunc(left, right), -2);
    try expect(@divFloor(left, right), -3);
    // try expect(@divExact(left, right), 2); // build error
}

test "整数型の割り算 符号あり 余りあり 負÷負" {
    const expect = lib.testing.expectEqual;

    const left: i8 = -7;
    const right: i8 = -3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    // try expect(@divExact(left, right), 2); // build error
}

test "整数型の割り算 符号あり ゼロ除算" {
    // const expect = lib.testing.expectEqual;

    // const left: i8 = -6;
    // const right: i8 = 0;

    // try expect(left / right, 2); // build error
    // try expect(@divTrunc(left, right), 2); // build error
    // try expect(@divFloor(left, right), 2); // build error
    // try expect(@divExact(left, right), 2); // build error
}

test "整数型の余り算 符号なし" {
    const expect = lib.testing.expectEqual;

    const left: u8 = 8;
    const right: u8 = 3;

    try expect(left % right, 2);
    try expect(@rem(left, right), 2);
    try expect(@mod(left, right), 2);
}

test "整数型の余り算 符号なし ゼロ除算" {
    // const expect = lib.testing.expectEqual;

    // const left: u8 = 8;
    // const right: u8 = 0;

    // try expect(left % right, 2); // build error
    // try expect(@rem(left, right), 2); // build error
    // try expect(@mod(left, right), 2); // build error
}

test "整数型の余り算 符号あり 正÷正" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 8;
    const right: i8 = 3;

    try expect(left % right, 2);
    try expect(@rem(left, right), 2);
    try expect(@mod(left, right), 2);
}

test "整数型の余り算 符号あり 正÷負" {
    const expect = lib.testing.expectEqual;

    const left: i8 = 8;
    const right: i8 = -3;

    // try expect(left % right, 2); // build error
    try expect(@rem(left, right), 2);
    try expect(@mod(left, right), -1);
}

test "整数型の余り算 符号あり 負÷正" {
    const expect = lib.testing.expectEqual;

    const left: i8 = -8;
    const right: i8 = 3;

    // try expect(left % right, 2); // build error
    try expect(@rem(left, right), -2);
    try expect(@mod(left, right), 1);
}

test "整数型の余り算 符号あり 負÷負" {
    const expect = lib.testing.expectEqual;

    const left: i8 = -8;
    const right: i8 = -3;

    // try expect(left % right, 2); // build error
    try expect(@rem(left, right), -2);
    try expect(@mod(left, right), -2);
}

test "整数型の余り算 符号あり ゼロ除算" {
    // const expect = lib.testing.expectEqual;

    // const left: i8 = 8;
    // const right: i8 = 0;

    // try expect(left % right, 2); // build error
    // try expect(@rem(left, right), 2); // build error
    // try expect(@mod(left, right), 2); // build error
}
