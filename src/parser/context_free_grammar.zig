const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const Grammar = struct {
    rules: []const ProductionRule,
};

pub const ProductionRule = struct {
    left: []const u8,
    right: []const []const u8,
};
