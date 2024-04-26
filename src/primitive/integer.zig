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

// 定数

pub const POINTER_SIZE = bitsOf(usize);

// 整数型を作る関数

pub fn Integer(signedness: std.builtin.Signedness, bits: u16) type {
    return @Type(.{ .Int = .{
        .signedness = signedness,
        .bits = bits,
    } });
}

test "符号とビットサイズから整数型を作成する" {
    const expect = lib.testing.expect;

    const IntType = Integer(.signed, 16);
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

/// 型のビットサイズを調べます。
pub fn bitsOf(comptime T: type) u16 {
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

    try expect(bitsOf(i32) == 32);
    try expect(bitsOf(u32) == 32);
    _ = bitsOf(usize);

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

test "整数型の足し算" {
    const expect = lib.testing.expect;

    const foo: u32 = 1;
    const bar: u32 = 0xffffffff;
    const baz: i32 = 1;
    const bam: i32 = -0x80000000;

    try expect(foo + 2 == 3);
    // try expect(bar + 1 == 0); // undefined behavior
    try expect(baz + -2 == -1);
    // try expect(bam + -1 == 0x7fffffff); // undefined behavior

    try expect(foo +% 2 == 3);
    try expect(bar +% 1 == 0);
    try expect(baz +% -2 == -1);
    try expect(bam +% -1 == 0x7fffffff);

    try expect(foo +| 2 == 3);
    try expect(bar +| 1 == 0xffffffff);
    try expect(baz +| -2 == -1);
    try expect(bam +| -1 == -0x80000000);

    try expect(@addWithOverflow(foo, 2)[0] == 3);
    try expect(@addWithOverflow(bar, 1)[0] == 0);
    try expect(@addWithOverflow(baz, -2)[0] == -1);
    try expect(@addWithOverflow(bam, -1)[0] == 0x7fffffff);

    try expect(@addWithOverflow(foo, 2)[1] == 0);
    try expect(@addWithOverflow(bar, 1)[1] == 1);
    try expect(@addWithOverflow(baz, -2)[1] == 0);
    try expect(@addWithOverflow(bam, -1)[1] == 1);
}
