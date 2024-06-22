const std = @import("std");
const lib = @import("../root.zig");

pub fn isSlice(value: type) bool {
    const Type = @typeInfo(value);

    return Type == .Pointer and Type.Pointer.size == .Slice;
}

test isSlice {
    try lib.assert.expect(isSlice([]u8));
    try lib.assert.expect(isSlice([]const u8));
    try lib.assert.expect(!isSlice(*[3]u8));
    try lib.assert.expect(!isSlice(*const [3]u8));
    try lib.assert.expect(!isSlice([*]u8));
    try lib.assert.expect(!isSlice([*]const u8));
}

pub fn equal(left: anytype, right: anytype) bool {
    comptime lib.assert.assert(isSlice(@TypeOf(left)));
    comptime lib.assert.assert(isSlice(@TypeOf(right)));

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

    try lib.assert.expect(equal(var_05, var_06));
    try lib.assert.expect(equal(var_05, var_07));
    try lib.assert.expect(!equal(var_05, var_08));
    try lib.assert.expect(!equal(var_05, var_09));
}

test {
    std.testing.refAllDecls(@This());
}
