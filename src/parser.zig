const std = @import("std");
const lib = @import("root.zig");

pub const combinator = @import("./parser/combinator.zig");

test {
    std.testing.refAllDecls(@This());
}
