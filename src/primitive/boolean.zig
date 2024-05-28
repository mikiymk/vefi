//! lib.primitive.boolean
//!
//! # 真偽値型
//!
//! 真偽値は`true`(真)と`false`(偽)の2つの値を持ちます。

const std = @import("std");
const lib = @import("../lib.zig");

/// 値が真偽値型かどうかを判定します。
pub fn isBoolean(value: anytype) bool {
    return @TypeOf(value) == bool;
}

/// 真偽値が真かどうかを判定します。
pub fn isTrue(value: bool) bool {
    return value;
}

/// 真偽値が偽かどうかを判定します。
pub fn isFalse(value: bool) bool {
    return !value;
}

/// 2つの真偽値の論理和を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `true`  |
/// | `true`  | `false` | `false` |
/// | `false` | `true`  | `false` |
/// | `false` | `false` | `false` |
pub fn lAnd(x: bool, y: bool) bool {
    return x and y;
}

/// 2つの真偽値の否定論理和を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `false` |
/// | `true`  | `false` | `true`  |
/// | `false` | `true`  | `true`  |
/// | `false` | `false` | `true`  |
pub fn lNotAnd(x: bool, y: bool) bool {
    return !(x and y);
}

/// 2つの真偽値の論理積を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `true`  |
/// | `true`  | `false` | `true`  |
/// | `false` | `true`  | `true`  |
/// | `false` | `false` | `false` |
pub fn lOr(x: bool, y: bool) bool {
    return x or y;
}

/// 2つの真偽値の否定論理積を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `false` |
/// | `true`  | `false` | `false` |
/// | `false` | `true`  | `false` |
/// | `false` | `false` | `true`  |
pub fn lNotOr(x: bool, y: bool) bool {
    return !(x or y);
}

/// 2つの真偽値の排他的論理和を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `false` |
/// | `true`  | `false` | `true`  |
/// | `false` | `true`  | `true`  |
/// | `false` | `false` | `false` |
pub fn lExOr(x: bool, y: bool) bool {
    return x != y;
}

/// 2つの真偽値の否定排他的論理和を計算します。
///
/// | x       | y       | result  |
/// | ------- | ------- | ------- |
/// | `true`  | `true`  | `true`  |
/// | `true`  | `false` | `false` |
/// | `false` | `true`  | `false` |
/// | `false` | `false` | `true`  |
pub fn lNotExOr(x: bool, y: bool) bool {
    return x == y;
}

/// 2つの真偽値の否定を計算します。
///
/// | x       | result  |
/// | ------- | ------- |
/// | `true`  | `false` |
/// | `false` | `true`  |
pub fn lNot(x: bool) bool {
    return !x;
}

/// 2つの真偽値を比較します。
/// 左辺値が右辺値より大きいかどうかを判定します。
/// ```
/// true == true;
/// true > false;
/// ```
pub fn compare(a: bool, b: bool) lib.common.Order {
    if (a == b) {
        return .equal;
    } else if (a) {
        return .greater_than;
    } else {
        return .less_than;
    }
}

const assert = lib.assert;

test "boolean is true or false" {
    try assert.expectEqual(isTrue(true), true);
    try assert.expectEqual(isTrue(false), false);

    try assert.expectEqual(isFalse(true), false);
    try assert.expectEqual(isFalse(false), true);
}

test "boolean calculate" {
    try assert.expectEqual(lAnd(true, true), true);
    try assert.expectEqual(lAnd(true, false), false);
    try assert.expectEqual(lAnd(false, true), false);
    try assert.expectEqual(lAnd(false, false), false);

    try assert.expectEqual(lNotAnd(true, true), false);
    try assert.expectEqual(lNotAnd(true, false), true);
    try assert.expectEqual(lNotAnd(false, true), true);
    try assert.expectEqual(lNotAnd(false, false), true);

    try assert.expectEqual(lOr(true, true), true);
    try assert.expectEqual(lOr(true, false), true);
    try assert.expectEqual(lOr(false, true), true);
    try assert.expectEqual(lOr(false, false), false);

    try assert.expectEqual(lNotOr(true, true), false);
    try assert.expectEqual(lNotOr(true, false), false);
    try assert.expectEqual(lNotOr(false, true), false);
    try assert.expectEqual(lNotOr(false, false), true);

    try assert.expectEqual(lExOr(true, true), false);
    try assert.expectEqual(lExOr(true, false), true);
    try assert.expectEqual(lExOr(false, true), true);
    try assert.expectEqual(lExOr(false, false), false);

    try assert.expectEqual(lNotExOr(true, true), true);
    try assert.expectEqual(lNotExOr(true, false), false);
    try assert.expectEqual(lNotExOr(false, true), false);
    try assert.expectEqual(lNotExOr(false, false), true);

    try assert.expectEqual(lNot(true), false);
    try assert.expectEqual(lNot(false), true);

    try assert.expectEqual(compare(true, true), .equal);
    try assert.expectEqual(compare(false, false), .equal);
    try assert.expectEqual(compare(true, false), .greater_than);
    try assert.expectEqual(compare(false, true), .less_than);
}
