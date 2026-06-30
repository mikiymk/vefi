const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

var rng: ?std.Random.Xoshiro256 = null;
/// すぐ使えるランダムジェネレーターを返す。
pub fn random() std.Random {
    if (rng == null) {
        rng = std.Random.Xoshiro256.init(@intCast(std.time.timestamp()));
    }

    return rng.?.random();
}
