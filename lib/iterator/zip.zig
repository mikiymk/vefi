/// 2つのイテレーターを合わせたイテレーター
/// 長い方のイテレーターと同じ長さになる
pub fn ZipLong(LeftIterator: type, RightIterator: type) type {
    lib.assert.assert(isIterator(Iterator1));
    lib.assert.assert(isIterator(Iterator2));
    const T1 = ItemOf(Iterator1);
    const T2 = ItemOf(Iterator2);

    return struct {
        pub const Item = struct { ?T1, ?T2 };

        iterator1: Iterator1,
        iterator2: Iterator2,

        pub fn init(iterator1: Iterator1, iterator2: Iterator2) @This() {
            return .{
                .iterator1 = iterator1,
                .iterator2 = iterator2,
            };
        }

        pub fn next(self: *@This()) ?Item {
            const item1 = self.iterator1.next();
            const item2 = self.iterator2.next();
            if (item1 != null or item2 != null) {
                return .{ item1, item2 };
            } else {
                return null;
            }
        }
    };
}

/// 2つのイテレーターを合わせたイテレーター
/// 短い方のイテレーターと同じ長さになる
pub fn ZipShort(LeftIterator: type, RightIterator: type) type {
    lib.assert.assert(isIterator(Iterator1));
    lib.assert.assert(isIterator(Iterator2));
    const T1 = ItemOf(Iterator1);
    const T2 = ItemOf(Iterator2);

    return struct {
        pub const Item = struct { T1, T2 };

        iterator1: Iterator1,
        iterator2: Iterator2,

        pub fn init(iterator1: Iterator1, iterator2: Iterator2) @This() {
            return .{
                .iterator1 = iterator1,
                .iterator2 = iterator2,
            };
        }

        pub fn next(self: *@This()) ?Item {
            const item1 = self.iterator1.next();
            const item2 = self.iterator2.next();
            if (item1 != null and item2 != null) {
                return .{ item1, item2 };
            } else {
                return null;
            }
        }
    };
}

/// 2つのイテレーターを合わせたイテレーター
/// 2つのイテレーターの長さが違うとパニックになる
pub fn ZipExact(LeftIterator: type, RightIterator: type) type {
    lib.assert.assert(isIterator(Iterator1));
    lib.assert.assert(isIterator(Iterator2));
    const T1 = ItemOf(Iterator1);
    const T2 = ItemOf(Iterator2);

    return struct {
        pub const Item = struct { T1, T2 };

        iterator1: Iterator1,
        iterator2: Iterator2,

        pub fn init(iterator1: Iterator1, iterator2: Iterator2) @This() {
            return .{
                .iterator1 = iterator1,
                .iterator2 = iterator2,
            };
        }

        pub fn next(self: *@This()) ?Item {
            const item1 = self.iterator1.next();
            const item2 = self.iterator2.next();
            if (item1 != null and item2 != null) {
                return .{ item1, item2 };
            } else if (item1 == null and item2 == null) {
                return null;
            } else {
                @panic("Iterator lengths do not match");
            }
        }
    };
}
