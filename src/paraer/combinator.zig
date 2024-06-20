pub const ParseResult(Parser: type) type {
    return struct { Parser.ValueType, usize };
}

pub fn U8() type {
    return struct {
        pub const ValueType = u8;
        pub fn parse(bytes: []const u8) ParseResult(@This()) {
            return .{ bytes[0], 1 };
        }
    };
}
