const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

/// Fisher-Yates のシャッフルアルゴリズムでランダムに並び変える。
pub fn shuffle(target: anytype, random: std.Random) void {
    if (target.length() < 2) return;
    var i = target.length() - 1;
    while (0 < i) : (i -= 1) {
        const j = random.intRangeLessThan(usize, 0, i + 1);
        target.swap(i, j);
    }
}
