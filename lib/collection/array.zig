const std = @import("std");
const lib = @import("../root.zig");

pub const StaticArray = @import("array/StaticArray.zig").StaticArray;
pub const StaticDynamicArray = @import("array/StaticDynamicArray.zig").StaticDynamicArray;
pub const DynamicArray = @import("array/DynamicArray.zig").DynamicArray;

pub const StaticDynamicCircularArray = @import("array/StaticDynamicCircularArray.zig").StaticDynamicCircularArray;
pub const DynamicCircularArray = @import("array/DynamicCircularArray.zig").DynamicCircularArray;

pub const StaticMultiDimensionalArray = @import("array/StaticMultiDimensionalArray.zig").StaticMultiDimensionalArray;

pub const StaticBitArray = @import("array/BitArray.zig");
pub const DynamicBitArray = @import("array/BitArray.zig");

/// TODO: あとで消す
pub const StringArray = @import("array/StringArray.zig");

pub fn isArray(T: type) bool {
    const match = lib.concept.Match.init(T);

    return match.hasDecl("Item") and
        match.hasFn("size") and
        match.hasFn("get") and
        match.hasFn("set");
}

pub fn isDynamicArray(T: type) bool {
    const match = lib.concept.Match.init(T);

    return isArray(T) and
        match.hasFn("clear") and
        match.hasFn("add") and
        match.hasFn("remove");
}

test "array is array" {
    const expect = lib.assert.expect;

    try expect(isArray(StaticArray(u8, 5)));
    try expect(isDynamicArray(DynamicArray(u8)));
    try expect(isDynamicArray(StringArray));
}
