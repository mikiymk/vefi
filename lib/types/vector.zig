const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn isVector(value: type) bool {
    const Type = @typeInfo(value);

    return Type == .vector;
}

test isVector {
    try lib.assert.expect(isVector(@Vector(5, bool)));
    try lib.assert.expect(isVector(@Vector(5, f64)));
    try lib.assert.expect(!isVector([3]u8));
    try lib.assert.expect(!isVector(*const [3]u8));
    try lib.assert.expect(!isVector([]u8));
    try lib.assert.expect(!isVector([*]const u8));
}
