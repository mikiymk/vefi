const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const DynamicArray = lib.collection.dynamic_array.DynamicArray;

const ParserInterface = lib.interface.Interface(.{
    .declarations = &.{
        .{ .name = "parse", .type = fn (lib.interface.This, Allocator, []const u8) lib.interface.AnyType },
    },
});

test "parser interface" {
    try lib.assert.expect(ParserInterface.isImplements(Byte));
}

pub fn Result(Value: type, Err: type) type {
    return (lib.allocator.AllocatorError || Err)!struct { Value, usize };
}

fn ValueTypeOf(Parser: type) type {
    const info = @typeInfo(@TypeOf(Parser.parse));
    const return_error_union = @typeInfo(info.Fn.return_type.?);
    const return_type = @typeInfo(return_error_union.ErrorUnion.payload);
    return return_type.Struct.fields[0].type;
}

fn ErrorOf(Parser: type) type {
    const info = @typeInfo(@TypeOf(Parser.parse));
    const return_error_union = @typeInfo(info.Fn.return_type.?);
    return return_error_union.ErrorUnion.error_set;
}

const Byte = struct {
    pub fn parse(_: @This(), _: Allocator, input: []const u8) Result(u8, error{ReachToEof}) {
        if (input.len < 1) {
            return error.ReachToEof;
        }
        return .{ input[0], 1 };
    }
};

/// 1バイトを符号無し整数として読み込む
pub const byte: Byte = .{};

test byte {
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    const parser = byte;

    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ 0x01, 1 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[1..]), .{ 0x23, 1 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[8..]), error.ReachToEof);
}

fn Tuple(Value: type, Fields: type) type {
    comptime lib.assert.assert(lib.types.Tuple.isTuple(Fields));
    const Err = blk: {
        var E = error{};
        for (@typeInfo(Fields).Struct.fields) |field| {
            E = E || ErrorOf(field.type);
        }
        break :blk E;
    };

    return struct {
        fields: Fields,

        pub fn parse(self: @This(), allocator: Allocator, bytes: []const u8) Result(Value, Err) {
            var value: Value = undefined;
            var read_count: usize = 0;

            inline for (self.fields, &value) |field, *v| {
                const tuple_value, const read_size = try field.parse(allocator, bytes[read_count..]);

                v.* = tuple_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

/// 値を順番に読み込み、タプルにする。
pub fn tuple(Value: type, fields: anytype) Tuple(Value, @TypeOf(fields)) {
    return .{ .fields = fields };
}

test tuple {
    const ParseInnerType = struct { u8, u8 };
    const ParseType = struct { u8, u8, ParseInnerType };
    const parser = tuple(ParseType, .{ byte, byte, tuple(ParseInnerType, .{ byte, byte }) });
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ .{ 0x01, 0x23, .{ 0x45, 0x67 } }, 4 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[3..]), .{ .{ 0x67, 0x89, .{ 0xab, 0xcd } }, 4 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[6..]), error.ReachToEof);
}

pub fn Block(Value: type, comptime fields: anytype) type {
    const field_names = blk: {
        var names: [fields.len][]const u8 = undefined;
        for (fields, &names) |f, *n| {
            n.* = f[0];
        }
        break :blk names;
    };

    const ParserTuple = lib.types.Tuple.Tuple(&blk: {
        var types: [fields.len]lib.types.Tuple.Field = undefined;
        for (fields, &types) |field, *t| {
            t.* = .{ .type = @TypeOf(field[1]) };
        }
        break :blk types;
    }, .{});

    const Err = blk: {
        var E = error{};
        for (fields) |field| {
            E = E || ErrorOf(@TypeOf(field[1]));
        }
        break :blk E;
    };

    return struct {
        fields: ParserTuple,

        pub fn parse(self: @This(), allocator: Allocator, bytes: []const u8) Result(Value, Err) {
            var value: Value = undefined;
            var read_count: usize = 0;

            // @fieldの名前テーブルを生成しないようにinlineをつける
            inline for (self.fields, field_names) |parser, name| {
                const tuple_value, const read_size = try parser.parse(allocator, bytes[read_count..]);

                @field(value, name) = tuple_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

/// 値を順番に読み込み、構造体にする。
pub fn block(Value: type, comptime fields: anytype) Block(Value, fields) {
    const ParserTuple = lib.types.Tuple.Tuple(&blk: {
        var types: [fields.len]lib.types.Tuple.Field = undefined;
        for (fields, &types) |field, *t| {
            t.* = .{ .type = @TypeOf(field[1]) };
        }
        break :blk types;
    }, .{});

    var parsers: ParserTuple = undefined;
    inline for (fields, &parsers) |field, *p| {
        p.* = field[1];
    }

    return .{ .fields = parsers };
}

test block {
    const ParseType = struct { foo: u8, bar: u8, baz: u8 };
    const parser = block(ParseType, &.{ .{ "foo", byte }, .{ "bar", byte }, .{ "baz", byte } });
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ .{ .foo = 0x01, .bar = 0x23, .baz = 0x45 }, 3 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[3..]), .{ .{ .foo = 0x67, .bar = 0x89, .baz = 0xab }, 3 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[6..]), error.ReachToEof);
}

pub fn ArrayFixed(Element: type, length: usize) type {
    const Value = [length]ValueTypeOf(Element);
    const Err = ErrorOf(Element);

    return struct {
        element: Element,

        pub fn parse(self: @This(), allocator: Allocator, input: []const u8) Result(Value, Err) {
            var value: Value = undefined;
            var read_count: usize = 0;

            for (&value) |*item| {
                const item_value, const read_size = try self.element.parse(allocator, input[read_count..]);
                item.* = item_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

/// 固定の回数を繰り返し読み込む。
pub fn arrayFixed(element: anytype, comptime length: usize) ArrayFixed(@TypeOf(element), length) {
    return .{ .element = element };
}

test arrayFixed {
    const parser = arrayFixed(byte, 3);
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ .{ 0x01, 0x23, 0x45 }, 3 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[3..]), .{ .{ 0x67, 0x89, 0xab }, 3 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[6..]), error.ReachToEof);
}

/// 終了部分が読み込まれるまで繰り返し読み込む。
pub fn ArraySentinel(Element: type, Sentinel: type) type {
    const Value = []const ValueTypeOf(Element);
    const Err = ErrorOf(Element) || blk: {
        const info = @typeInfo(ErrorOf(Sentinel));
        const error_set = info.ErrorSet orelse break :blk error{};
        var new_error_set: [error_set.len - 1]lib.builtin.Type.Error = undefined;
        var i = 0;
        for (error_set) |err| {
            if (lib.types.Slice.equal(u8, err.name, "UnmatchValue")) {
                continue;
            }
            new_error_set[i] = err;
            i += 1;
        }

        break :blk @Type(.{ .ErrorSet = &new_error_set });
    };

    return struct {
        element: Element,
        sentinel: Sentinel,

        pub fn parse(self: @This(), allocator: Allocator, bytes: []const u8) Result(Value, Err) {
            var value = DynamicArray(ValueTypeOf(Element)).init();
            defer value.deinit(allocator);
            var read_count: usize = 0;

            while (true) {
                if (self.sentinel.parse(allocator, bytes[read_count..])) |sentinel_read| {
                    _, const sentinel_size = sentinel_read;

                    const slice = try value.copyToSlice(allocator);

                    return .{ slice, read_count + sentinel_size };
                } else |err| {
                    switch (err) {
                        error.UnmatchValue => {
                            const item_value, const read_size = try self.element.parse(allocator, bytes[read_count..]);
                            try value.push(allocator, item_value);
                            read_count += read_size;
                            continue;
                        },
                        else => |e| return e,
                    }
                }
            }
        }
    };
}

pub fn arraySemtinel(element: anytype, sentinel: anytype) ArraySentinel(@TypeOf(element), @TypeOf(sentinel)) {
    return .{ .element = element, .sentinel = sentinel };
}

test arraySemtinel {
    const parser = arraySemtinel(byte, constant(byte, 0x89));
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    {
        const value, const size = try parser.parse(allocator, bytes[0..]);
        try lib.assert.expectEqual(value, &.{ 0x01, 0x23, 0x45, 0x67 });
        try lib.assert.expectEqual(size, 5);

        allocator.free(value);
    }
    {
        const value, const size = try parser.parse(allocator, bytes[3..]);
        try lib.assert.expectEqual(value, &.{0x67});
        try lib.assert.expectEqual(size, 2);

        allocator.free(value);
    }
    try lib.assert.expectEqual(parser.parse(allocator, bytes[6..]), error.ReachToEof);
}

pub fn ArrayCounted(Count: type, Item: type) type {
    const DynamicItemArray = lib.collection.dynamic_array.DynamicArray(Item.Value);
    const Value = []const Item.Value;

    return struct {
        count: Count,
        item: Item,

        pub fn parse(self: @This(), allocator: Allocator, bytes: []const u8) Result(Value, error{}) {
            var value = DynamicItemArray.init();
            defer value.deinit(allocator);
            var read_count: usize = 0;
            var item_count = 0;

            const count, const count_size = try self.count.parse(allocator, bytes[read_count..]);
            read_count += count_size;

            while (item_count < count) : (item_count += 1) {
                const item_value, const read_size = try self.item.parse(allocator, bytes[read_count..]);
                try value.push(allocator, item_value);
                read_count += read_size;
            }

            const slice = try value.copyToSlice(allocator);
            return .{ slice, read_count };
        }
    };
}

pub fn arrayCounted(count: anytype, element: anytype) ArrayCounted(@TypeOf(count), @TypeOf(element)) {
    return .{ .count = count, .element = element };
}

test arrayCounted {}

/// 特定の値のみを読み込む。
/// `==`で比較できる型が利用できる。
pub fn Constant(Parser: type) type {
    const Value = ValueTypeOf(Parser);
    const Err = ErrorOf(Parser) || error{UnmatchValue};

    return struct {
        parser: Parser,
        value: Value,

        pub fn parse(self: @This(), allocator: Allocator, bytes: []const u8) Result(Value, Err) {
            const read_value, const read_size = try self.parser.parse(allocator, bytes[0..]);

            if (read_value == self.value) {
                return .{ read_value, read_size };
            } else {
                return error.UnmatchValue;
            }
        }
    };
}

pub fn constant(parser: anytype, value: ValueTypeOf(@TypeOf(parser))) Constant(@TypeOf(parser)) {
    return .{ .parser = parser, .value = value };
}

test constant {
    const parser = constant(byte, 0x01);
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ 0x01, 1 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[1..]), error.UnmatchValue);
    try lib.assert.expectEqual(parser.parse(allocator, bytes[8..]), error.ReachToEof);
}
