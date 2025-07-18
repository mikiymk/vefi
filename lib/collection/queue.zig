const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;

pub const SinglyListQueue = @import("queue/SinglyListQueue.zig").SinglyListQueue;
pub const TwoStacksQueue = @import("queue/TwoStacksQueue.zig").TwoStacksQueue;
pub const DoublyListDeque = @import("queue/DoublyListDeque.zig").DoublyListDeque;
pub const CircularArrayDeque = @import("queue/CircularArrayDeque.zig").CircularArrayDeque;
