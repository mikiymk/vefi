const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const sort = @import("algorithm/sort.zig");
pub const random = @import("algorithm/random.zig");
