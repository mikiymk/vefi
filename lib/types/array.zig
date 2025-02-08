const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn isArray(value: type) bool {
    const Type = @typeInfo(value);

    return Type == .Array;
}

test isArray {
    try lib.assert.expect(isArray([3]u8));
    try lib.assert.expect(!isArray([*]u8));
    try lib.assert.expect(!isArray([]u8));
    try lib.assert.expect(!isArray(*[3]u8));
}
