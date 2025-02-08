const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

/// イテレータの`next()`が返す型を得る。
pub fn isIterator(Iterator: type) bool {
    const info = @typeInfo(@TypeOf(Iterator));

    switch (info) {
        inline .Struct, .Enum, .Union => |i| i.decls,
        else => return false,
    }
}

/// イテレータの`next()`が返す型を得る。
pub fn ItemOf(Iterator: type) type {
    const info = @typeInfo(@TypeOf(Iterator.next));

    return lib.types.Optional.NonOptional(info.Fn.return_type);
}

/// それぞれの値を変更して出力するイテレータ
pub fn Map(Iterator: type, NewType: type) type {
    lib.assert.assert(isIterator(Iterator));
    lib.assert.assert(!lib.types.Optional.isOptional(NewType));
    const T = ItemOf(Iterator);

    return struct {
        iterator: Iterator,
        map_fn: *const fn (value: T) NewType,

        pub fn next(self: *@This()) ?NewType {
            return self.map_fn(self.iterator.next() orelse return null);
        }
    };
}

/// それぞれの値を変更して出力するイテレータ
pub fn map(
    NewType: type,
    iterator: anytype,
    map_fn: *const fn (value: ItemOf(@TypeOf(iterator))) NewType,
) Map(@TypeOf(iterator), NewType) {
    return .{
        .iterator = iterator,
        .map_fn = map_fn,
    };
}

pub fn Filter(Iterator: type) type {
    lib.assert.assert(isIterator(Iterator));
    const T = ItemOf(Iterator);

    return struct {
        iterator: Iterator,
        filter_fn: *const fn (value: T) bool,

        pub fn next(self: *@This()) ?T {
            return while (self.iterator.next()) |value| {
                if (self.filter_fn(value)) {
                    break value;
                }
            } else null;
        }
    };
}
