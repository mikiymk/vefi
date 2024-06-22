const std = @import("std");
const lib = @import("../root.zig");

pub fn ParseResult(Parser: type) type {
    return error{ParseError}!struct { Parser.Value, usize };
}

pub fn U8() type {
    return struct {
        pub const Value: type = u8;
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
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

    try lib.assert.expectEqual(Parser.Value, u8);
    try lib.assert.expectEqual(Parser.parse(bytes[0..]), .{ 0x01, 1 });
    try lib.assert.expectEqual(Parser.parse(bytes[1..]), .{ 0x23, 1 });
    try lib.assert.expectEqual(Parser.parse(bytes[8..]), error.ParseError);
}

pub fn ConstString(comptime keyword: []const u8) type {
    return struct {
        pub const Value: type = []const u8;
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            if (bytes.len < keyword.len) {
                return error.ParseError;
            }

            const value: []const u8 = bytes[0..keyword.len];
            if (!lib.types.Slice.equal(keyword, value)) {
                return error.ParseError;
            }

            return .{ value, value.len };
        }
    };
}

test ConstString {
    const Parser = ConstString("abc");
    const bytes = [_]u8{ 0x61, 0x62, 0x63, 0x67, 0x89, 0xab, 0xcd, 0xef };

    try lib.assert.expectEqual(Parser.Value, []const u8);
    try lib.assert.expectEqual(Parser.parse(bytes[0..]), .{ "abc", 3 });
    try lib.assert.expectEqual(Parser.parse(bytes[3..]), error.ParseError);
}

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
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            var value: Value = undefined;
            var read_count: usize = 0;

            inline for (fields, 0..) |field, i| {
                const tuple_value, const read_size = try field.parse(bytes[read_count..]);
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

    try lib.assert.expectEqual(Parser.Value, struct { u8, u8, u8 });
    try lib.assert.expectEqual(Parser.parse(bytes[0..]), .{ .{ 0x01, 0x23, 0x45 }, 3 });
    try lib.assert.expectEqual(Parser.parse(bytes[3..]), .{ .{ 0x67, 0x89, 0xab }, 3 });
    try lib.assert.expectEqual(Parser.parse(bytes[6..]), error.ParseError);
}

pub fn Struct(comptime fields: anytype) type {
    comptime lib.assert.assert(lib.types.Array.isArray(fields));
    comptime lib.assert.assert(lib.types.Struct.equalType(lib.types.Array.ItemOf(fields), struct { []const u8, type }));

    return struct {
        pub const Value: type = @Type(.{ .Struct = .{
            .fields = fields,
            .is_tuple = false,
        } });
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            var value: Value = undefined;
            var read_count: usize = 0;

            inline for (fields) |field| {
                const field_name, const field_parser = field;
                const tuple_value, const read_size = field_parser.parse(bytes[read_count..]);
                @field(value, field_name) = tuple_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

pub fn ArrayFix(Item: type, length: usize) type {
    return struct {
        pub const Value = [length]Item.Value;
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            var value: Value = undefined;
            var read_count: usize = 0;

            for (&value) |*item| {
                const item_value, const read_size = Item.parse(bytes[read_count..]);
                item.* = item_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}

test {
    std.testing.refAllDecls(@This());
}
