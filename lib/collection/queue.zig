const std = @import("std");
const lib = @import("../root.zig");

const Allocator = std.mem.Allocator;

/// データを先入れ先出し(FIFO)で保持するコレクションです。
/// リングバッファを使用した実装
pub fn Queue(T: type) type {
    return struct {
        pub const Value = T;

        value: []Value,
        head: usize,
        tail: usize,

        /// 空のキューを作成します。
        pub fn init() @This() {
            return .{
                .value = &[_]T{},
                .head = 0,
                .tail = 0,
            };
        }

        /// メモリを破棄し、キューを終了します。
        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.value);
        }

        fn isFull(self: @This()) bool {
            return self.value.len <= self.count() + 1;
        }

        /// キューの要素数を数えます。
        pub fn count(self: @This()) usize {
            return self.head - self.tail;
        }

        /// キューの先頭に要素を追加します。
        pub fn enqueue(self: *@This(), allocator: Allocator, item: Value) Allocator.Error!void {
            if (self.isFull()) {
                try self.extendSize(allocator);
            }

            self.value[self.head % self.value.len] = item;
            self.head += 1;
        }

        /// キューの末尾から要素を取り出します。
        pub fn dequeue(self: *@This()) ?Value {
            if (self.count() == 0) {
                return null;
            }

            const item = self.value[self.tail % self.value.len];
            self.tail += 1;
            return item;
        }

        /// キューの末尾の要素を取得します。
        pub fn peek(self: @This()) ?Value {
            if (self.count() == 0) {
                return null;
            } else {
                return self.value[self.tail % self.value.len];
            }
        }

        const OuterThis = @This();
        pub const Iterator = struct {
            ref: *OuterThis,

            pub fn next(self: *@This()) ?Value {
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
            var new_array = try allocator.alloc(Value, new_length);

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

test Queue {
    const Q = Queue(usize);
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
