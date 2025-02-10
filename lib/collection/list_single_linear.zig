pub fn SingleLinearList(T: type) type {
    const Element = struct {
            next: ?*Element = null,
            value: T,

            pub fn init(a: Allocator, value: T) *Element {
                const next: *Element = try a.create(Element);
                next.* = Element{
                    .value = value,
                };

                return next;
            }

            pub fn addAfter(self: *Element, a: Allocator, value: T) void {
                const new_element = a.create(Element);
                new_element.* = .{
                    .next = self.next,
                    .value = value,
                };

                self.next = new_element;
            }
    };

    return struct {
        const Self = @This();

        /// リストが持つ値の型
        pub const Item = T;
        pub const Element = Element;

        value: ?*Element = null,

        /// 空のリストとして初期化する
        pub fn init() Self {
            return .{};
        }

        /// すべてのメモリを解放する。
        pub fn deinit(self: *Self, a: Allocator) void {
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

        /// リストの要素数を数える
        pub fn size(self: Self) usize {
            var element = self.value;
            var count: usize = 0;
            while (element) |e| {
                element = e.next;
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

        pub fn insertFirst(self: *Self, a: Allocator, value: T) AllocatorError!void {
            const next: *Element = try a.create(Element);
            next.* = Element{
                .next = self.value,
                .value = value,
            };

            self.value = next;
        }

        pub fn insertLast(self: *Self, a: Allocator, value: T) AllocatorError!void {
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
    };
}
