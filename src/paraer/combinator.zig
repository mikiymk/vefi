pub const ParseResult(Parser: type) type {
    return error{ParseError}!struct { Parser.Value, usize };
}

pub fn U8() type {
    return struct {
        pub const Value = u8;
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            if (bytes.len < 1) {
                return error.ParseError;
            }
            return .{ bytes[0], 1 };
        }
    };
}

pub fn Const(comptime keyword: []const u8) type {
    return struct {
        pub const Value = []const u8;
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            if (bytes.len < keyword.len) {
                return error.ParseError;
            }

            const value = bytes[0..keyword.len];
            if (!equal(keyword, value)) {
                return error.ParseError;
            }

            return .{ value, value.len };
        }
    };
}

pub fn Tuple(comptime fields: [_]type) type {
    return struct {
        pub const Value = @Type(.{ .Struct = .{
            .fields = fields,
            .is_tuple = true,
        }});
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            var value: Value = undefined;
            var read_count: usize = 0;

            inline for (fields, 0..) |field, i| {
                const tuple_value, const read_size = fields.parse(bytes[read_count..]);
                tuple[i] = tuple_value;
                read_count += read_size;
            }

            return .{ value, read_count };
        }
    };
}
