const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn isSlice(value: type) bool {
    const Type = @typeInfo(value);

    return Type == .pointer and Type.pointer.size == .slice;
}

test isSlice {
    try lib.assert.expect(isSlice([]u8));
    try lib.assert.expect(isSlice([]const u8));

    try lib.assert.expect(!isSlice(*[3]u8));
    try lib.assert.expect(!isSlice(*const [3]u8));
    try lib.assert.expect(!isSlice([*]u8));
    try lib.assert.expect(!isSlice([*]const u8));
}

pub fn equal(T: type, left: []const T, right: []const T) bool {
    if (left.len != right.len) {
        return false;
    }

    for (left, right) |l, r| {
        if (!lib.common.equal(l, r)) {
            return false;
        }
    }

    return true;
}

test equal {
    var var_01 = [_]u8{ 1, 2, 3 };
    var var_02 = [_]u8{ 1, 2, 3 };
    var var_03 = [_]u8{ 1, 2, 3, 4 };
    var var_04 = [_]u8{ 2, 3, 4 };
    const var_05: []u8 = &var_01;
    const var_06: []u8 = &var_02;
    const var_07: []const u8 = &var_01;
    const var_08: []const u8 = &var_03;
    const var_09: []const u8 = &var_04;

    try lib.assert.expect(equal(u8, var_05, var_06));
    try lib.assert.expect(equal(u8, var_05, var_07));
    try lib.assert.expect(!equal(u8, var_05, var_08));
    try lib.assert.expect(!equal(u8, var_05, var_09));
}

pub fn includes(T: type, slice: []const T, item: T) bool {
    for (slice) |i| {
        if (lib.common.equal(i, item)) {
            return true;
        }
    }

    return false;
}

test includes {
    var var_01 = [_]u8{ 1, 2, 3 };
    const var_02: []u8 = &var_01;

    try lib.assert.expect(includes(u8, var_02, 1));
    try lib.assert.expect(includes(u8, var_02, 2));
    try lib.assert.expect(includes(u8, var_02, 3));
    try lib.assert.expect(!includes(u8, var_02, 4));
}
