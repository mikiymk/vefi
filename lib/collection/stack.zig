const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;

test {
    std.testing.refAllDecls(@This());
}

pub const ArrayStack = @import("stack/array.zig").ArrayStack;
pub const ListStack = @import("stack/list.zig").ListStack;

pub fn isStack(T: type) bool {
    const match = lib.concept.Match.init(T);

    return match.hasDecl("Item") and
        match.hasFn("size") and
        match.hasFn("pushBack") and
        match.hasFn("popBack");
}
