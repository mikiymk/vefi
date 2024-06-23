const std = @import("std");
const lib = @import("../root.zig");

pub fn ParseResult(Parser: type) type {
    return (error{ParseError} || lib.allocator.AllocatorError)!struct { Parser.Value, usize };
}

/// 1バイトを符号無し整数として読み込む
///
/// ```zig
/// const Parser = U8();
/// const bytes: []const u8 = "abc";
///
/// const result, const length = Parser.parse(bytes);
///
/// assert(result == 'a');
/// assert(length == 1);
/// ```
pub fn U8() type {
    return struct {
        pub const Value: type = u8;
        pub fn parse(_: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            if (bytes.len < 1) {
                return error.ParseError;
            }
            return .{ bytes[0], 1 };
        }
    };
}

test U8 {
    const Parser = U8();
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(Parser.Value, u8);
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[0..]), .{ 0x01, 1 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[1..]), .{ 0x23, 1 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[8..]), error.ParseError);
}

/// 特定の値のみを読み込む。
/// `==`で比較できる型が利用できる。
pub fn Const(Parser: type, value: Parser.Value) type {
    return struct {
        pub const Value: type = Parser.Value;
        pub fn parse(allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            const read_value, const read_size = try Parser.parse(allocator, bytes[0..]);

            if (read_value == value) {
                return .{ read_value, read_size };
            } else {
                return error.ParseError;
            }
        }
    };
}

test Const {
    const Parser = Const(U8(), 0x01);
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(Parser.Value, u8);
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[0..]), .{ 0x01, 1 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[1..]), error.ParseError);
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[8..]), error.ParseError);
}

/// 特定の文字列を読み込む。
pub fn ConstString(comptime keyword: []const u8) type {
    return struct {
        pub const Value: type = []const u8;
        pub fn parse(_: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            if (bytes.len < keyword.len) {
                return error.ParseError;
            }

            const value: []const u8 = bytes[0..keyword.len];
            if (!lib.types.Slice.equal(u8, keyword, value)) {
                return error.ParseError;
            }

            return .{ value, value.len };
        }
    };
}

test ConstString {
    const Parser = ConstString("abc");
    const bytes = [_]u8{ 0x61, 0x62, 0x63, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(Parser.Value, []const u8);
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[0..]), .{ "abc", 3 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[3..]), error.ParseError);
}

/// 値を順番に読み込み、タプルにする。
pub fn Tuple(comptime fields: anytype) type {
    comptime lib.assert.assert(lib.types.Tuple.isTuple(@TypeOf(fields)));

    return struct {
        pub const Value: type = lib.types.Tuple.Tuple(&blk: {
            var struct_fields: [fields.len]lib.types.Tuple.Field = undefined;
            for (&struct_fields, fields) |*sf, f| {
                sf.* = .{ .type = f.Value };
            }

            break :blk struct_fields;
        }, .{});
        pub fn parse(allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            var value: Value = undefined;
            var read_count: usize = 0;

            inline for (fields, 0..) |field, i| {
                const tuple_value, const read_size = try field.parse(allocator, bytes[read_count..]);
                value[i] = tuple_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

test Tuple {
    const Parser = Tuple(.{ U8(), U8(), U8() });
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(Parser.Value, struct { u8, u8, u8 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[0..]), .{ .{ 0x01, 0x23, 0x45 }, 3 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[3..]), .{ .{ 0x67, 0x89, 0xab }, 3 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[6..]), error.ParseError);
}

/// 値を順番に読み込み、構造体にする。
pub fn Struct(comptime fields: []const struct { []const u8, type }) type {
    return struct {
        pub const Value: type = lib.types.Struct.Struct(&blk: {
            var struct_fields: [fields.len]lib.types.Struct.Field = undefined;
            for (&struct_fields, fields) |*sf, f| {
                var name: [f[0].len:0]u8 = undefined;
                for (&name, f[0]) |*n, fnm| {
                    n.* = fnm;
                }

                sf.* = .{
                    .name = &name,
                    .type = f[1].Value,
                };
            }

            break :blk struct_fields;
        }, .{});
        pub fn parse(allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            var value: Value = undefined;
            var read_count: usize = 0;

            inline for (fields) |field| {
                const field_name, const field_parser = field;
                const tuple_value, const read_size = try field_parser.parse(allocator, bytes[read_count..]);
                @field(value, field_name) = tuple_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

test Struct {
    const Parser = Struct(&.{ .{ "foo", U8() }, .{ "bar", U8() }, .{ "baz", U8() } });
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(Parser.parse(allocator, bytes[0..]), .{ .{ .foo = 0x01, .bar = 0x23, .baz = 0x45 }, 3 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[3..]), .{ .{ .foo = 0x67, .bar = 0x89, .baz = 0xab }, 3 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[6..]), error.ParseError);
}

/// 固定の回数を繰り返し読み込む。
pub fn ArrayFix(Item: type, length: usize) type {
    return struct {
        pub const Value = [length]Item.Value;
        pub fn parse(allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            var value: Value = undefined;
            var read_count: usize = 0;

            for (&value) |*item| {
                const item_value, const read_size = try Item.parse(allocator, bytes[read_count..]);
                item.* = item_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

test ArrayFix {
    const Parser = ArrayFix(U8(), 3);
    const bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    const allocator = std.testing.allocator;

    try lib.assert.expectEqual(Parser.Value, [3]u8);
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[0..]), .{ .{ 0x01, 0x23, 0x45 }, 3 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[3..]), .{ .{ 0x67, 0x89, 0xab }, 3 });
    try lib.assert.expectEqual(Parser.parse(allocator, bytes[6..]), error.ParseError);
}

/// 終了部分が読み込まれるまで繰り返し読み込む。
pub fn ArraySentinel(Item: type, Sentinel: type) type {
    const DynamicItemArray = lib.collection.dynamic_array.DynamicArray(Item.Value);
    return struct {
        pub const Value = []const Item.Value;
        pub fn parse(allocator: lib.allocator.Allocator, bytes: []const u8) ParseResult(@This()) {
            var value = DynamicItemArray.init();
            defer value.deinit(allocator);
            var read_count: usize = 0;

            while (true) {
                _, const sentinel_size = Sentinel.parse(allocator, bytes[read_count..]) catch |err| switch (err) {
                    error.ParseError => {
                        const item_value, const read_size = try Item.parse(allocator, bytes[read_count..]);
                        try value.push(allocator, item_value);
                        read_count += read_size;
                        continue;
                    },
                    else => return err,
                };

                const slice = try value.copyToSlice(allocator);

                return .{ slice, read_count + sentinel_size };
            }
        }
    };
}

test ArraySentinel {
    const Parser = ArraySentinel(U8(), Const(U8(), 0x89));
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

test {
    std.testing.refAllDecls(@This());
}
