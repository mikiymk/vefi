const std = @import("std");
const lib = @import("../root.zig");

pub const node = struct {
    pub const linear = @import("list/node/linear.zig");
    pub const circular = @import("list/node/circular.zig");
    pub const sentinel = @import("list/node/sentinel.zig");
};

pub const List = @import("list/SinglyList.zig").SinglyList;
pub const SentinelList = @import("list/SentinelList.zig").SentinelList;
pub const CircularList = @import("list/CircularList.zig").CircularList;
pub const DoublyList = @import("list/DoublyList.zig").DoublyList;

pub const test_list = @import("list/test.zig");
