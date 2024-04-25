//!

const std = @import("std");
const lib = @import("../lib.zig");
const assert = lib.testing.assert;

const POINTER_SIZE = bitsOf(usize);

pub fn Integer(signedness: std.builtin.Signedness, bits: u16) type {
    return @Type(.{ .Int = .{
        .signedness = signedness,
        .bits = bits,
    } });
}

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

/// 型がコンパイル時整数(`comptime_int`)かどうかを判定します。
pub fn isComptimeInt(comptime T: type) bool {
    const info = @typeInfo(T);

    return info == .ComptimeInt;
}

/// 型が整数かどうかを判定します。
pub fn isInteger(comptime T: type) bool {
    const info = @typeInfo(T);
    return info == .Int or info == .ComptimeInt;
}

pub fn bitsOf(comptime T: type) u16 {
    assert(isInteger(T));

    return @typeInfo(T).Int.bits;
}

test "符号付き・符号なし整数型" {
    try lib.testing.expect(isSignedInteger(i32));
    try lib.testing.expect(!isSignedInteger(u32));
    try lib.testing.expect(!isSignedInteger(f32));
    try lib.testing.expect(isSignedInteger(isize));
    try lib.testing.expect(!isSignedInteger(usize));
    try lib.testing.expect(!isSignedInteger(comptime_int));

    try lib.testing.expect(!isUnsignedInteger(i32));
    try lib.testing.expect(isUnsignedInteger(u32));
    try lib.testing.expect(!isUnsignedInteger(f32));
    try lib.testing.expect(!isUnsignedInteger(isize));
    try lib.testing.expect(isUnsignedInteger(usize));
    try lib.testing.expect(!isUnsignedInteger(comptime_int));

    try lib.testing.expect(isInteger(i32));
    try lib.testing.expect(isInteger(u32));
    try lib.testing.expect(!isInteger(f32));
    try lib.testing.expect(isInteger(isize));
    try lib.testing.expect(isInteger(usize));
    try lib.testing.expect(isInteger(comptime_int));

    try lib.testing.expect(bitsOf(i32) == 32);
    try lib.testing.expect(bitsOf(u32) == 32);
    _ = bitsOf(usize);
}

pub fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    assert(isInteger(@TypeOf(a)));

    return a + b;
}

test "整数型の演算" {
    try lib.testing.expect(add(1, 2) == 3);
}
