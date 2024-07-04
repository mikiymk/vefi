const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const RegularExpression = union(enum) {
    string: []const u8,
    sequential: []RegularExpression,
    selection: []RegularExpression,
    repetition: *RegularExpression,
    group: *RegularExpression,

    pub fn compile(expression: []const u8) @This() {
        return .{
            .string = expression,
        };
    }

    pub fn match(self: @This(), string: []const u8) ?[]const u8 {
        switch (self) {
            .string => |s| {
                var current_position: usize = 0;

                while (current_position <= string.len - s.len) : (current_position += 1) {
                    if (self.matchAtPos(string, current_position)) |current_string| {
                        return current_string;
                    }
                }

                return null;
            },

            .sequential => {
                return null;
            },

            .selection => {
                return null;
            },

            .repetition => {
                return null;
            },

            .group => {
                return null;
            },
        }
    }

    pub fn matchAtPos(self: @This(), string: []const u8, position: usize) ?[]const u8 {
        switch (self) {
            .string => |s| {
                const current_string = string[position..][0..s.len];
                if (lib.string.equal(s, current_string)) {
                    return current_string;
                } else {
                    return null;
                }
            },

            .sequential => {
                return null;
            },

            .selection => {
                return null;
            },

            .repetition => {
                return null;
            },

            .group => {
                return null;
            },
        }
    }
};

test "文字列" {
    const regexp = RegularExpression.compile("foo");

    try lib.assert.expectEqual(regexp.match("foo bar"), "foo");
    try lib.assert.expectEqual(regexp.match("bar foo"), "foo");
    try lib.assert.expectEqual(regexp.match("bar baz"), null);
}

test "選択" {
    // const regexp = RegularExpression.compile("foo|bar");

    // try lib.assert.expectEqual(regexp.match("foo baz"), "foo");
    // try lib.assert.expectEqual(regexp.match("bar baz"), "bar");
    // try lib.assert.expectEqual(regexp.match("baz fom"), null);
    // try lib.assert.expectEqual(regexp.match("foo bar"), "foo");
    // try lib.assert.expectEqual(regexp.match("bar foo"), "bar");
}

test "繰り返し" {
    // const regexp = RegularExpression.compile("fo*");

    // try lib.assert.expectEqual(regexp.match("foo bar"), "foo");
    // try lib.assert.expectEqual(regexp.match("f bar"), "f");
    // try lib.assert.expectEqual(regexp.match("foooo bar"), "foooo");
    // try lib.assert.expectEqual(regexp.match("bar baz"), null);
}

test "組み合わせ" {
    // const regexp = RegularExpression.compile("(f|b)o*");

    // try lib.assert.expectEqual(regexp.match("foo bar"), "foo");
    // try lib.assert.expectEqual(regexp.match("f bar"), "f");
    // try lib.assert.expectEqual(regexp.match("bar baz"), "b");
    // try lib.assert.expectEqual(regexp.match("boo foo"), "boo");
    // try lib.assert.expectEqual(regexp.match("ar az"), null);
}
