//!

const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

///
pub fn equalApproximateAbsolute(left: anytype, right: @TypeOf(left), tolerance: @TypeOf(left)) bool {
    const result = @abs(left - right) < tolerance;

    if (comptime lib.types.Vector.isVector(@TypeOf(result))) {
        return @reduce(.And, result);
    }

    return result;
}

///
pub fn equalApproximateRelative(left: anytype, right: @TypeOf(left), tolerance: @TypeOf(left)) bool {
    const result = @abs(left - right) < tolerance * @max(@abs(left), @abs(right));

    if (comptime lib.types.Vector.isVector(@TypeOf(result))) {
        return @reduce(.And, result);
    }

    return result;
}
