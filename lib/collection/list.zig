const std = @import("std");
const lib = @import("../root.zig");

pub const LinearNode = @import("list/node/LinearNode.zig");
pub const CircularNode = @import("list/node/CircularNode.zig");
pub const SentinelNode = @import("list/node/SentinelNode.zig");

pub const SingleLinearList = @import("list/SingleLinearList.zig").SingleLinearList;
pub const SingleLinearSentinelList = @import("list/SingleLinearSentinelList.zig").SingleLinearSentinelList;
pub const SingleCircularList = @import("list/SingleCircularList.zig").SingleCircularList;
pub const SingleCircularSentinelList = @import("list/SingleCircularSentinelList.zig").SingleCircularSentinelList;
pub const DoubleLinearList = @import("list/DoubleLinearList.zig").DoubleLinearList;
pub const DoubleLinearSentinelList = @import("list/DoubleLinearSentinelList.zig").DoubleLinearSentinelList;
pub const DoubleCircularList = @import("list/DoubleCircularList.zig").DoubleCircularList;
pub const DoubleCircularSentinelList = @import("list/DoubleCircularSentinelList.zig").DoubleCircularSentinelList;

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
