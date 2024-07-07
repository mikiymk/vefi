const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn HashTable(K: type, V: type) type {
    return struct {
        pub const Key = K;
        pub const Value = V;
    };
}
