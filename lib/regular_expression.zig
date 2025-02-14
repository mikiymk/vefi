const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

const Allocator = std.mem.Allocator;
const Slice = lib.types.Slice;

pub const NondeterministicTransitions = struct {
    current_state: usize,
    input: ?u8,

    next_state: []const usize,
};

pub const NondeterministicFiniteAutomaton = struct {
    pub const initial_state: usize = 0;

    transitions: []const NondeterministicTransitions,
    accept_states: []const usize,

    fn getTransition(self: @This(), state: usize, input: u8) ?[]const usize {
        for (self.transitions) |transition| {
            if (transition.current_state == state and transition.input == input) {
                return transition.next_state;
            }
        }

        return null;
    }

    // breadth first
    // depth first
    pub fn accepts(self: @This(), a: Allocator, string: []const u8) Allocator.Error!bool {
        const DynamicArray = lib.collection.array.dynamic_array.DynamicArray(usize, .{});

        var states = DynamicArray.init();
        defer states.deinit(a);

        try states.pushBack(a, initial_state);

        for (string) |c| {
            var next_states = DynamicArray.init();

            for (states.asSlice()) |state| {
                const state_next_states = self.getTransition(state, c) orelse continue;
                for (state_next_states) |state_next_state| {
                    try next_states.pushBack(a, state_next_state);
                }
            }

            if (next_states._size == 0) {
                return false;
            }

            states.deinit(a);
            states = next_states;
        }

        for (states.asSlice()) |state| {
            if (Slice.includes(usize, self.accept_states, state)) {
                return true;
            }
        } else return false;
    }
};

test NondeterministicFiniteAutomaton {
    const allocator = std.testing.allocator;
    {
        const nfa = NondeterministicFiniteAutomaton{
            .transitions = &.{
                .{ .current_state = 0, .input = '0', .next_state = &.{0} },
                .{ .current_state = 0, .input = '1', .next_state = &.{1} },
                .{ .current_state = 1, .input = '0', .next_state = &.{0} },
                .{ .current_state = 1, .input = '1', .next_state = &.{1} },
            },
            .accept_states = &.{1},
        };

        try lib.assert.expect(!(try nfa.accepts(allocator, "0")));
        try lib.assert.expect(try nfa.accepts(allocator, "1"));
        try lib.assert.expect(try nfa.accepts(allocator, "01"));
        try lib.assert.expect(!(try nfa.accepts(allocator, "10")));
        try lib.assert.expect(try nfa.accepts(allocator, "01100101"));
    }

    // {
    //     const nfa = NondeterministicFiniteAutomaton{
    //         .transitions = &.{
    //             .{ .current_state = 0, .input = 'a', .next_state = &.{ 1, 2 } },
    //             .{ .current_state = 1, .input = 'b', .next_state = &.{2} },
    //             .{ .current_state = 2, .input = null, .next_state = &.{0} },
    //         },
    //         .accept_states = &.{2},
    //     };

    //     try lib.assert.expect(!(try nfa.accepts(allocator, "a")));
    //     try lib.assert.expect(try nfa.accepts(allocator, "ab"));
    //     try lib.assert.expect(try nfa.accepts(allocator, "aba"));
    //     try lib.assert.expect(!(try nfa.accepts(allocator, "b")));
    //     try lib.assert.expect(!(try nfa.accepts(allocator, "abb")));
    //     try lib.assert.expect(try nfa.accepts(allocator, "abaaa"));
    // }
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
