const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const AllocatorError = lib.allocator.AllocatorError;

// 配列の関数
// get set
// size clear
// indexOf
// sort reverse

// 動的配列
// pushFront pushBack popFront popBack
// concat slice

// 配列の種類
// 静的・動的
// 線形・環状

pub const static_array = @import("./array-static.zig");
pub const dynamic_array = @import("./array-dynamic.zig");
pub const static_multi_dimensional_array = @import("./array-static-multi-dimensional.zig");

pub const Range = struct {
    begin: usize,
    end: usize,
};

pub fn isArray(T: type) bool {
    const interface = lib.interface.match(T);

    if (!interface.hasFunc("get")) return false;
    if (!interface.hasFunc("set")) return false;
    if (!interface.hasFunc("size")) return false;
    return true;
}

pub fn isDynamicArray(T: type) bool {
    const interface = lib.interface.match(T);

    if (!isArray(T)) return false;

    if (!interface.hasFunc("get")) return false;
    if (!interface.hasFunc("set")) return false;
    if (!interface.hasFunc("size")) return false;
    return true;
}

test "array is array" {
    try lib.assert.expect(isArray(static_array.StaticArray(u8, 5, .{})));
    try lib.assert.expect(isArray(dynamic_array.DynamicArray(u8, .{})));
    try lib.assert.expect(isDynamicArray(dynamic_array.DynamicArray(u8, .{})));
}
