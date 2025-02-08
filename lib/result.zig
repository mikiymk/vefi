const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn Result(S: type, F: type) type {
    return union(enum) {
        success: Success,
        failure: Failure,

        pub const Success = S;
        pub const Failure = F;

        pub fn isResult(Self: type) bool {
            return Self == Result(Self.Success, Self.Failure);
        }
    };
}
