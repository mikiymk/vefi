const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;

pub const SinglyListQueue = @import("queue/SinglyListQueue.zig").SinglyListQueue;
pub const StackQueue = @import("queue/StackQueue.zig").StackQueue;

pub const DoublyListDeque = @import("queue/DoublyListDeque.zig").DoublyListDeque;
pub const CircularArrayDeque = @import("queue/CircularArrayDeque.zig").CircularArrayDeque;

pub fn isQueue(T: type) bool {
    const match = lib.concept.Match.init(T);

    return match.hasDecl("Item") and
        match.hasFn("size") and
        match.hasFn("pushBack") and
        match.hasFn("popFront");
}

pub fn isDeque(T: type) bool {
    const match = lib.concept.Match.init(T);

    return isQueue(T) and
        match.hasFn("pushFront") and
        match.hasFn("popBack");
}
