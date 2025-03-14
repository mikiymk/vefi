const std = @import("std");
const lib = @import("../root.zig");

pub const StaticArray = @import("array/static.zig").StaticArray;
pub const DynamicArray = @import("array/dynamic.zig").DynamicArray;
pub const StaticMultiDimensionalArray = @import("array/static-multi-dimensional.zig").StaticMultiDimensionalArray;
pub const StringArray = @import("array/string.zig");
pub const bit_array = struct {};

pub fn isArray(T: type) bool {
    const match = lib.interface.match(T);

    return match.hasFn("get") and
        match.hasFn("set") and
        match.hasFn("size");
}

pub fn isDynamicArray(T: type) bool {
    const match = lib.interface.match(T);

    return isArray(T) and
        match.hasFn("pushFront") and
        match.hasFn("pushBack") and
        match.hasFn("popFront") and
        match.hasFn("popBack");
}

test "array is array" {
    const expect = lib.assert.expect;

    try expect(isArray(StaticArray(u8, 5)));
    try expect(isDynamicArray(DynamicArray(u8)));
    try expect(isDynamicArray(StringArray));
}
