pub const ParseResult(Parser: type) type {
    return error{ParseError}!struct { Parser.ValueType, usize };
}

pub fn U8() type {
    return struct {
        pub const ValueType = u8;
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            if (bytes.len < 1) {
                return error.ParseError;
            }
            return .{ bytes[0], 1 };
        }
    };
}
