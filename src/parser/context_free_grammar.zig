const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn Grammar(Term: type, NonTerm: type) type {
    return struct {
        rules: []const ProductionRule(Term, NonTerm),
    };
}

pub fn ProductionRule(Term: type, NonTerm: type) type {
    return struct {
        left: NonTerm,
        right: []const Symbol(Term, NonTerm),
    };
}

pub fn Symbol(Term: type, NonTerm: type) type {
    return union(enum) {
        term: Term,
        non_term: NonTerm,
    };
}
