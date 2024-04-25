//!

const std = @import("std");
const lib = @import("../lib.zig");
const Allocator = std.mem.Allocator;
const AllocError = Allocator.Error;

/// 連結リスト
///
/// - *T* リストが持つ値の型
pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();

        /// リストが持つ値の型
        pub const Item = T;
        pub const Element = struct {
            next: ?*Element = null,
            value: T,

            pub fn create(a: Allocator, value: T) *Element {
                const next: *Element = try a.create(Element);
                next.* = Element{
                    .value = value,
                };

                return next;
            }

            pub fn insertNext(self: *Element, a: Allocator, value: T) void {
                const new_element = a.create(Element);
                new_element.* = .{
                    .next = self.next,
                    .value = value,
                };

                self.next = new_element;
            }
        };

        value: ?*Element = null,

        /// 空のリストとして初期化する
        pub fn init() Self {
            return .{};
        }

        /// リストの要素数を数える
        pub fn size(self: Self) usize {
            var e = self.value;
            var count: usize = 0;
            while (e) |n| {
                e = n.next;
                count += 1;
            }

            return count;
        }

        pub fn getFirstElement(self: Self) ?*Element {
            return self.value;
        }

        pub fn getLastElement(self: Self) ?*Element {
            var elem = self.value;
            while (elem) |e| {
                const next = e.next;

                if (next) |n| {
                    elem = n;
                } else {
                    return elem;
                }
            }

            return null;
        }

        pub fn getElement(self: Self, n: usize) ?*Element {
            var count_down = n;
            var elem = self.value;
            while (elem) |e| {
                if (count_down == 0) {
                    return e;
                }

                elem = e.next;
                count_down -= 1;
            }

            return null;
        }

        pub fn getFirst(self: Self) ?T {
            const elem = self.getFirstElement();
            if (elem) |e| {
                return e.value;
            } else {
                return null;
            }
        }

        pub fn getLast(self: Self) ?T {
            const elem = self.getLastElement();
            if (elem) |e| {
                return e.value;
            } else {
                return null;
            }
        }

        pub fn get(self: Self, n: usize) ?T {
            const elem = self.getElement(n);
            if (elem) |e| {
                return e.value;
            } else {
                return null;
            }
        }

        pub fn insertFirst(self: *Self, a: Allocator, value: T) AllocError!void {
            const next: *Element = try a.create(Element);
            next.* = Element{
                .next = self.value,
                .value = value,
            };

            self.value = next;
        }

        pub fn insertLast(self: *Self, a: Allocator, value: T) AllocError!void {
            var elem = self.value;
            while (elem) |e| {
                const next = e.next;

                if (next) |n| {
                    elem = n;
                } else {
                    const last = try a.create(Element);
                    last.* = Element{
                        .value = value,
                    };

                    e.next = last;

                    return;
                }
            }
        }

        pub fn insert(self: Self, a: Allocator, n: usize, value: T) void {
            _ = .{ self, a, n, value };
        }

        pub fn copy(self: Self, a: Allocator) Self {
            _ = .{ self, a };
        }

        pub const Iterator = struct {};

        pub fn iterator(self: Self) Iterator {
            _ = self;
        }

        pub fn equal(left: Self, right: Self) bool {
            _ = left;
            _ = right;
        }

        pub fn clear(self: *Self, a: Allocator) void {
            var elem = self.value;
            self.value = null;

            while (elem) |e| {
                const next = e.next;
                a.destroy(e);

                if (next) |n| {
                    elem = n;
                } else {
                    return;
                }
            }
        }
    };
}

fn assert(ok: bool) error{AssertionFailed}!void {
    if (!ok) {
        return error.AssertionFailed;
    }
}

test "list" {
    const L = List(u8);
    const a = std.testing.allocator;

    var list = L.init();

    // list == []
    try assert(@TypeOf(list) == List(u8));
    try assert(list.size() == 0);
    try assert(list.getFirstElement() == null);
    try assert(list.getLastElement() == null);

    try list.insertFirst(a, 5);
    try list.insertFirst(a, 6);

    // list == [6, 5]
    try assert(list.size() == 2);
    try assert(list.getFirstElement().?.value == 6);
    try assert(list.getLastElement().?.value == 5);

    try list.insertLast(a, 7);
    try list.insertLast(a, 8);

    // list == [6, 5, 7, 8]
    try assert(list.size() == 4);
    try assert(list.getFirst() == 6);
    try assert(list.getLast() == 8);

    list.clear(a);
}
