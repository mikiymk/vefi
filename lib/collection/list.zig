const std = @import("std");
const lib = @import("../root.zig");

pub const node = struct {
    pub const linear = @import("list/node/linear.zig");
    pub const circular = @import("list/node/circular.zig");
    pub const sentinel = @import("list/node/sentinel.zig");
};

pub const List = @import("list/List.zig").List;
pub const SentinelList = @import("list/SentinelList.zig").SentinelList;
pub const CircularList = @import("list/CircularList.zig").CircularList;
pub const DoublyList = @import("list/DoublyList.zig").DoublyList;

pub const test_list = @import("list/test.zig");

pub fn isList(T: type) bool {
    const match = lib.concept.Match.init(T);

    return match.hasFn("size") and
        match.hasFn("clear") and
        match.hasFn("getNode") and
        match.hasFn("get") and
        match.hasFn("set") and
        match.hasFn("add") and
        match.hasFn("remove");
}

pub fn isDoubleList(T: type) bool {
    const match = lib.concept.Match.init(T);

    return isList(T) and
        match.hasFn("getNodeFromLast") and
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
