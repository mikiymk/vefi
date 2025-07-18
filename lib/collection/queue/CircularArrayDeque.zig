const std = @import("std");
const lib = @import("../../root.zig");

const Allocator = std.mem.Allocator;

pub fn CircularArrayDeque(T: type) type {
    return struct {
        const Queue = @This();
        pub const Item = T;

        values: []Item,
        head: usize,
        tail: usize,
        filled: bool,

        /// 空のキューを作成します。
        pub fn init() @This() {
            return .{
                .values = &[_]Item{},
                .head = 0,
                .tail = 0,
                .filled = true,
            };
        }

        /// メモリを破棄し、キューを終了します。
        pub fn deinit(self: *@This(), a: Allocator) void {
            a.free(self.values);
            self.* = undefined;
        }

        /// キューの要素数を数えます。
        pub fn size(self: @This()) usize {
            return if (self.filled) self.values.len else if (self.head < self.tail) self.head + self.values.len - self.tail else self.head - self.tail;
        }

        /// キューの先頭に要素を追加します。
        pub fn pushFront(self: *@This(), allocator: Allocator, item: Item) Allocator.Error!void {
            if (self.filled) {
                try self.extendSize(allocator);
            }

            self.values[self.head] = item;
            self.head += 1;
            if (self.head == self.values.len)
                self.head = 0;
            self.filled = self.head == self.tail;
        }

        pub fn pushLast(self: *@This(), allocator: Allocator, item: Item) Allocator.Error!void {
            if (self.filled) {
                try self.extendSize(allocator);
            }

            self.values[self.tail] = item;
            self.tail = if (self.tail == 0) self.values.len else self.tail;
            self.tail -= 1;
            self.filled = self.head == self.tail;
        }

        pub fn popFront(self: *@This()) ?Item {
            if (self.size() == 0) return null;

            const item = self.value[self.head];
            self.head = if (self.head == 0) self.values.len else self.head;
            self.head -= 1;
            return item;
        }

        /// キューの末尾から要素を取り出します。
        pub fn popLast(self: *@This()) ?Item {
            if (self.size() == 0) return null;

            const item = self.value[self.tail];
            self.tail += 1;
            if (self.tail == self.values.len)
                self.tail = 0;
            return item;
        }

        pub fn peekFirst(self: @This()) ?Item {
            if (self.size() == 0) {
                return null;
            } else {
                return self.value[self.head];
            }
        }

        /// キューの末尾の要素を取得します。
        pub fn peekLast(self: @This()) ?Item {
            if (self.size() == 0) {
                return null;
            } else {
                return self.value[self.tail];
            }
        }

        const OuterThis = @This();
        pub const Iterator = struct {
            ref: *OuterThis,

            pub fn next(self: *@This()) ?Item {
                return self.ref.dequeue();
            }
        };

        /// キューの要素を順番に取り出すイテレータを作成します。
        pub fn iterator(self: *@This()) Iterator {
            return .{
                .ref = self,
            };
        }

        fn extendSize(self: *@This(), allocator: Allocator) Allocator.Error!void {
            const initial_length = 8;
            const extend_factor = 2;

            const old_array = self.value;
            const old_length = self.value.len;

            const new_length: usize = if (self.value.len == 0) initial_length else self.value.len * extend_factor;
            var new_array = try allocator.alloc(Item, new_length);

            var i: usize = 0;
            const c = self.count();
            while (i < c) : (i += 1) {
                new_array[i] = old_array[(self.tail + i) % old_length];
            }

            self.value = new_array;
            self.head = c;
            self.tail = 0;
            allocator.free(old_array);
        }
    };
}

test CircularArrayDeque {
    const Q = CircularArrayDeque(usize);
    const a = std.testing.allocator;

    var q = Q.init();
    defer q.deinit(a);

    try q.enqueue(a, 3);
    try q.enqueue(a, 4);
    try q.enqueue(a, 5);

    try lib.assert.expectEqual(q.count(), 3);
    try lib.assert.expectEqual(q.dequeue(), 3);

    try q.enqueue(a, 6);

    try lib.assert.expectEqual(q.count(), 3);
    try lib.assert.expectEqual(q.peek(), 4);
    try lib.assert.expectEqual(q.dequeue(), 4);
    try lib.assert.expectEqual(q.dequeue(), 5);
    try lib.assert.expectEqual(q.dequeue(), 6);
    try lib.assert.expectEqual(q.dequeue(), null);

    try q.enqueue(a, 3);
    try q.enqueue(a, 4);
    try q.enqueue(a, 5);

    var iter = q.iterator();

    try lib.assert.expectEqual(iter.next(), 3);
    try lib.assert.expectEqual(iter.next(), 4);
    try lib.assert.expectEqual(iter.next(), 5);
    try lib.assert.expectEqual(iter.next(), null);

    try lib.assert.expectEqual(q.dequeue(), null);

    for (0..100) |i| {
        try q.enqueue(a, i);
        try lib.assert.expectEqual(q.dequeue(), i);
    }

    try lib.assert.expect(q.value.len < 100);

    try q.enqueue(a, 1);
    try q.enqueue(a, 2);
    try q.enqueue(a, 3);
    try q.enqueue(a, 4);
    try q.enqueue(a, 5);
    try q.enqueue(a, 6);
    try q.enqueue(a, 7);
    try q.enqueue(a, 8);
    try q.enqueue(a, 9);
    try q.enqueue(a, 10);

    try lib.assert.expectEqual(q.dequeue(), 1);
    try lib.assert.expectEqual(q.dequeue(), 2);
    try lib.assert.expectEqual(q.dequeue(), 3);
    try lib.assert.expectEqual(q.dequeue(), 4);
    try lib.assert.expectEqual(q.dequeue(), 5);
    try lib.assert.expectEqual(q.dequeue(), 6);
    try lib.assert.expectEqual(q.dequeue(), 7);
    try lib.assert.expectEqual(q.dequeue(), 8);
    try lib.assert.expectEqual(q.dequeue(), 9);
    try lib.assert.expectEqual(q.dequeue(), 10);
    try lib.assert.expectEqual(q.dequeue(), null);
}
