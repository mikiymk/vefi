const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

/// 文法。
/// 生成規則の集まりでできている。
/// 最初の規則の左辺に登場する非終端記号を開始記号とする。
pub fn Grammar(Term: type, NonTerm: type) type {
    return struct {
        rules: []const ProductionRule(Term, NonTerm),
    };
}

/// 生成規則。
/// 左辺に1個の非終端記号を持つ。
/// 右辺に0個以上の終端記号または非終端記号を持つ。
pub fn ProductionRule(Term: type, NonTerm: type) type {
    return struct {
        left: NonTerm,
        right: []const Symbol(Term, NonTerm),
    };
}

/// 終端記号または非終端記号。
pub fn Symbol(Term: type, NonTerm: type) type {
    return union(enum) {
        term: Term,
        non_term: NonTerm,
    };
}
