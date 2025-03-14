const std = @import("std");
const lib = @import("../root.zig");

pub const generic_list = @import("list/generic.zig");
pub const generic_list_sentinel = @import("list/generic-sentinel.zig");

pub const SingleLinearList = @import("list/single-linear.zig").SingleLinearList;
pub const SingleLinearSentinelList = @import("list/single-linear-sentinel.zig").SingleLinearSentinelList;
pub const SingleCircularList = @import("list/single-circular.zig").SingleCircularList;
pub const SingleCircularSentinelList = @import("list/single-circular-sentinel.zig").SingleCircularSentinelList;
pub const DoubleLinearList = @import("list/double-linear.zig").DoubleLinearList;
pub const DoubleLinearSentinelList = @import("list/double-linear-sentinel.zig").DoubleLinearSentinelList;
pub const DoubleCircularList = @import("list/double-circular.zig").DoubleCircularList;
pub const DoubleCircularSentinelList = @import("list/double-circular-sentinel.zig").DoubleCircularSentinelList;

pub const test_list = @import("list/test.zig");

pub fn isList(T: type) bool {
    const match = lib.interface.match(T);

    return match.hasFn("size") and
        match.hasFn("clear") and
        match.hasFn("get") and
        match.hasFn("getFirst") and
        match.hasFn("getLast") and
        match.hasFn("add") and
        match.hasFn("addFirst") and
        match.hasFn("addLast") and
        match.hasFn("remove") and
        match.hasFn("removeFirst") and
        match.hasFn("removeLast");
}

pub fn isDoubleList(T: type) bool {
    const match = lib.interface.match(T);

    return isList(T) and
        match.hasFn("getFromLast");
}

test "list is list" {
    const expect = lib.assert.expect;

    try expect(isList(SingleLinearList(u8)));
    try expect(isList(SingleLinearSentinelList(u8)));
    try expect(isList(SingleCircularList(u8)));
    try expect(isList(SingleCircularSentinelList(u8)));
    try expect(isDoubleList(DoubleLinearList(u8)));
    try expect(isDoubleList(DoubleLinearSentinelList(u8)));
    try expect(isDoubleList(DoubleCircularList(u8)));
    try expect(isDoubleList(DoubleCircularSentinelList(u8)));
}
