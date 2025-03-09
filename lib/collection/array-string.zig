const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;
const Array = lib.collection.DynamicArray;
const Self = @This();

values: Array(u8),
last_indexes: Array(usize),

pub fn init() @This() {
    return .{
        .values = &.{},
        .last_indexes = &.{},
    };
}

pub fn get(self: @This(), index: usize) []u8 {
    _ = self;
    _ = index;
}
