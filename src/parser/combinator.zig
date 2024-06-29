const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = lib.allocator.Allocator;
const DynamicArray = lib.collection.dynamic_array.DynamicArray;

const ParserInterface = lib.interface.Interface(.{
    .declarations = &.{
        .{ "parse", fn (Allocator, []const u8) lib.interface.AnyType },
    },
});

test "parser interface" {
    try lib.assert.expect(ParserInterface.isImplements(Byte));
}

pub const Error = error{ParseError} || lib.allocator.AllocatorError;
pub fn Result(Value: type, Err: type) type {
    return (Error || Err)!struct { Value, usize };
}

fn ValueTypeOf(Parser: type) type {
    const info = @typeInfo(@TypeOf(Parser.parse));
    const return_type = @typeInfo(info.Fn.return_type.?);
    return return_type.Struct.fields[0].type;
}

const Byte = struct {
    pub fn parse(_: @This(), _: Allocator, input: []const u8) ParseResult(u8, error{}) {
        if (input.len < 1) {
            return error.ReachEol;
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

    try lib.assert.expectEqual(parser.Value, u8);
    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ 0x01, 1 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[1..]), .{ 0x23, 1 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[8..]), error.ParseError);
}

fn Tuple(Value: type, Fields: type) type {
    comptime lib.assert.assert(lib.types.Tuple.isTuple(@TypeOf(fields)));

    return struct {
        fields: Fields,

        pub fn parse(allocator: Allocator, bytes: []const u8) ParseResult(Value, error{}) {
            var value: Value = undefined;
            var read_count: usize = 0;

            for (self.fields, &value) |field, *v| {
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

    try lib.assert.expectEqual(parser.Value, struct { u8, u8, u8 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ .{ 0x01, 0x23, .{ 0x45, 0x67 } }, 4 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[3..]), .{ .{ 0x67, 0x89, .{ 0xab, 0xcd } }, 4 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[6..]), error.ParseError);
}

pub fn Block(Value: type, comptime fields: anytype) type {
    const field_names = blk: {
        var names: [fields.len][]const u8 = undefined;
        for (fields, &names) |f, *n| {
            n.* = f[0];
        }
        break :blk names;
    };

    const ParserTuple = lib.types.Tuple(.{
            fields.map(|f| @TypeOf(f[1]))
        }, .{});

    return struct {
        fields: ParserTuple,

        pub fn parse(allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            var value: Value = undefined;
            var read_count: usize = 0;

            // @fieldの名前テーブルを生成しないようにinlineをつける
            inline for (fields, names) |parser, name| {
                const tuple_value, const read_size = try parser.parse(allocator, bytes[read_count..]);

                @field(value, name) = tuple_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

/// 値を順番に読み込み、構造体にする。
pub fn block(Value: type, comptime fields: []const struct { []const u8, type }) Struct(Value, fields) {
    const parsers = 0;

    return .{ .fields = parsers };
}

test block {
    const ParseType = struct { foo: u8, bar: u8, baz: u8 };
    const parser = block(ParseType, &.{ .{ "foo", byte }, .{ "bar", byte }, .{ "baz", byte } });
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ .{ .foo = 0x01, .bar = 0x23, .baz = 0x45 }, 3 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[3..]), .{ .{ .foo = 0x67, .bar = 0x89, .baz = 0xab }, 3 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[6..]), error.ParseError);
}

pub fn ArrayFixed(Element: type) type {
    const Value = [length]ValueTypeOf(element);

    return struct {
        element: Element,
        length: usize,

        pub fn parse(allocator: lib.allocator.Allocator, input: []const u8) ParseResult(Value, error{}) {
            var value: Value = undefined;
            var read_count: usize = 0;

            for (&value) |*item| {
                const item_value, const read_size = try element.parse(allocator, input[read_count..]);
                item.* = item_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

/// 固定の回数を繰り返し読み込む。
pub fn arrayFixed(element: anytype, length: usize) ArrayFixed(element) {
    return .{ .element = element, .length = length };
}

test arrayFixed {
    const parser = arrayFixed(byte, 3);
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(parser.Value, [3]u8);
    try lib.assert.expectEqual(parser.parse(allocator, bytes[0..]), .{ .{ 0x01, 0x23, 0x45 }, 3 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[3..]), .{ .{ 0x67, 0x89, 0xab }, 3 });
    try lib.assert.expectEqual(parser.parse(allocator, bytes[6..]), error.ParseError);
}

/// 終了部分が読み込まれるまで繰り返し読み込む。
pub fn ArraySentinel(element: anytype, sentinel: anytype) type {
    const Value = []const ValueTypeOf(element);

    return struct {
        element: Element,
        sentinel: Sentinel,

        pub fn parse(allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(Value, error{}) {
            var value = DynamicArray(ValueTypeOf(element)).init();
            defer value.deinit(allocator);
            var read_count: usize = 0;

            while (true) {
                if (sentinel.parse(allocator, bytes[read_count..])) |sentinel_read| {
                    _, const sentinel_size = sentinel_read;

                    const slice = try value.copyToSlice(allocator);

                    return .{ slice, read_count + sentinel_size };
                } else |err| {
                    switch (err) {
                        error.ParseError => {
                            const item_value, const read_size = try element.parse(allocator, bytes[read_count..]);
                            try value.push(allocator, item_value);
                            read_count += read_size;
                            continue;
                        },
                        else => return err,
                    }
                }
            }
        }
    };
}

pub fn arraySemtinel(element: anytype, sentinel: anytype) ArraySemtinel(@TypeOf(element), @TypeOf(sentinel)) {
    return .{ .element = element, .sentinel = sentinel };
}

test arraySemtinel {
    const Parser = ArraySentinel(byte, constant(byte, 0x89));
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(Parser.Value, []const u8);
    {
        const value, const size = try Parser.parse(allocator, bytes[0..]);
        try lib.assert.expectEqual(value, &.{ 0x01, 0x23, 0x45, 0x67 });
        try lib.assert.expectEqual(size, 5);

        allocator.free(value);
    }
    {
        const value, const size = try Parser.parse(allocator, bytes[3..]);
        try lib.assert.expectEqual(value, &.{0x67});
        try lib.assert.expectEqual(size, 2);

        allocator.free(value);
    }
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[6..]), error.ParseError);
}

pub fn ArrayCount(Count: type, Item: type) type {
    const DynamicItemArray = lib.collection.dynamic_array.DynamicArray(Item.Value);
    return struct {
        pub const Value = []const Item.Value;
        pub fn parse(allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            var value = DynamicItemArray.init();
            defer value.deinit(allocator);
            var read_count: usize = 0;
            var item_count = 0;

            const count, const count_size = try Count.parse(allocator, bytes[read_count..]);
            read_count += count_size;

            while (item_count < count) : (item_count += 1) {
                const item_value, const read_size = try Item.parse(allocator, bytes[read_count..]);
                try value.push(allocator, item_value);
                read_count += read_size;
            }

            const slice = try value.copyToSlice(allocator);
            return .{ slice, read_count };
        }
    };
}

pub fn arrayCounted(count: element, element: anytype) ArrayCounted(@TypeOf(count), @TypeOf(element)) {
    return .{ .count = count, .element = element };
}

test arrayCounted {}

/// 特定の値のみを読み込む。
/// `==`で比較できる型が利用できる。
pub fn Constant(parser: anytype) type {
    const Value = ValueTypeOf(@TypeOf(parser));

    return struct {
        parser: Parser,
        value: Value,

        pub fn parse(self: @This(), allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(Value) {
            const read_value, const read_size = try parser.parse(allocator, bytes[0..]);

            if (read_value == self.value) {
                return .{ read_value, read_size };
            } else {
                return error.ParseError;
            }
        }
    };
}

pub fn constant(parser: anytype, value: ValueTypeOf(@TypeOf(parser))) Constant(parser, value) {
    return .{ .parser = parser, .value = value };
}

test constant {
    const Parser = constant(byte, 0x01);
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(Parser.Value, u8);
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[0..]), .{ 0x01, 1 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[1..]), error.ParseError);
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[8..]), error.ParseError);
}
