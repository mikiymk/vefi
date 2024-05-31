//! lib.primitive.boolean
//!
//! # 真偽値型
//!
//! 真偽値は`true`(真)と`false`(偽)の2つの値を持ちます。

const std = @import("std");
const lib = @import("../lib.zig");

const expect = lib.assert.expectEqual;
const expectString = lib.assert.expectEqualString;

/// 値が真偽値型かどうかを判定します。
pub fn isBoolean(value: anytype) bool {
    return @TypeOf(value) == bool;
}

/// 真偽値が真かどうかを判定します。
pub fn isTrue(value: bool) bool {
    return value;
}

test isTrue {
    try expect(isTrue(true), true);
    try expect(isTrue(false), false);
}

/// 真偽値が偽かどうかを判定します。
pub fn isFalse(value: bool) bool {
    return !value;
}

test isFalse {
    try expect(isFalse(true), false);
    try expect(isFalse(false), true);
}

/// 2つの真偽値の論理和を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `true`  |
/// | `true`  | `false` | `false` |
/// | `false` | `true`  | `false` |
/// | `false` | `false` | `false` |
pub fn logicalAnd(x: bool, y: bool) bool {
    return x and y;
}

test logicalAnd {
    try expect(logicalAnd(true, true), true);
    try expect(logicalAnd(true, false), false);
    try expect(logicalAnd(false, true), false);
    try expect(logicalAnd(false, false), false);
}

/// 2つの真偽値の否定論理和を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `false` |
/// | `true`  | `false` | `true`  |
/// | `false` | `true`  | `true`  |
/// | `false` | `false` | `true`  |
pub fn logicalNotAnd(x: bool, y: bool) bool {
    return !(x and y);
}

test logicalNotAnd {
    try expect(logicalNotAnd(true, true), false);
    try expect(logicalNotAnd(true, false), true);
    try expect(logicalNotAnd(false, true), true);
    try expect(logicalNotAnd(false, false), true);
}

/// 2つの真偽値の論理積を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `true`  |
/// | `true`  | `false` | `true`  |
/// | `false` | `true`  | `true`  |
/// | `false` | `false` | `false` |
pub fn logicalOr(x: bool, y: bool) bool {
    return x or y;
}

test logicalOr {
    try expect(logicalOr(true, true), true);
    try expect(logicalOr(true, false), true);
    try expect(logicalOr(false, true), true);
    try expect(logicalOr(false, false), false);
}

/// 2つの真偽値の否定論理積を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `false` |
/// | `true`  | `false` | `false` |
/// | `false` | `true`  | `false` |
/// | `false` | `false` | `true`  |
pub fn logicalNotOr(x: bool, y: bool) bool {
    return !(x or y);
}

test logicalNotOr {
    try expect(logicalNotOr(true, true), false);
    try expect(logicalNotOr(true, false), false);
    try expect(logicalNotOr(false, true), false);
    try expect(logicalNotOr(false, false), true);
}

/// 2つの真偽値の排他的論理和を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `false` |
/// | `true`  | `false` | `true`  |
/// | `false` | `true`  | `true`  |
/// | `false` | `false` | `false` |
pub fn logicalXor(x: bool, y: bool) bool {
    return x != y;
}

test logicalXor {
    try expect(logicalXor(true, true), false);
    try expect(logicalXor(true, false), true);
    try expect(logicalXor(false, true), true);
    try expect(logicalXor(false, false), false);
}

/// 2つの真偽値の否定排他的論理和を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `true`  |
/// | `true`  | `false` | `false` |
/// | `false` | `true`  | `false` |
/// | `false` | `false` | `true`  |
pub fn logicalNotXor(x: bool, y: bool) bool {
    return x == y;
}

test logicalNotXor {
    try expect(logicalNotXor(true, true), true);
    try expect(logicalNotXor(true, false), false);
    try expect(logicalNotXor(false, true), false);
    try expect(logicalNotXor(false, false), true);
}

/// 2つの真偽値の否定を計算します。
///
/// | x       | result  |
/// | ------- | ------- |
/// | `true`  | `false` |
/// | `false` | `true`  |
pub fn logicalNot(x: bool) bool {
    return !x;
}

test logicalNot {
    try expect(logicalNot(true), false);
    try expect(logicalNot(false), true);
}

/// 2つの真偽値を比較します。
pub fn equal(x: bool, y: bool) bool {
    return x == y;
}

test equal {
    try expect(equal(true, true), true);
    try expect(equal(false, false), true);
    try expect(equal(true, false), false);
    try expect(equal(false, true), false);
}

/// 2つの真偽値を比較します。
/// 左辺値が右辺値より大きいかどうかを判定します。
/// ```
/// true == true;
/// true > false;
/// ```
pub fn compare(x: bool, y: bool) lib.common.Order {
    if (x == y) {
        return .equal;
    } else if (x) {
        return .greater_than;
    } else {
        return .less_than;
    }
}

test compare {
    try expect(compare(true, true), .equal);
    try expect(compare(false, false), .equal);
    try expect(compare(true, false), .greater_than);
    try expect(compare(false, true), .less_than);
}

/// 真偽値を文字列に変換します。
pub fn toString(x: bool) []const u8 {
    if (x) {
        return "true";
    } else {
        return "false";
    }
}

test toString {
    try expectString(toString(true), "true");
    try expectString(toString(false), "false");
}
