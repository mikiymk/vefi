const std = @import("std");
const lib = @import("root.zig");

/// 型の確認をする
pub const Match = struct {
    type: type,

    fn info(self: Match) std.builtin.Type {
        return @typeInfo(self.type);
    }

    pub fn is(self: Match, target: type) bool {
        return self.type == target;
    }

    pub fn isInt(self: Match) bool {
        return self.info() == .Int;
    }

    pub fn isFloat(self: Match) bool {
        return self.info() == .Float;
    }

    pub fn isNum(self: Match) bool {
        return self.isInt() or self.isFloat();
    }

    /// == !=で比較可能
    pub fn isEqualable(self: Match) bool {
        return self.isInt() or self.isFloat();
    }

    pub fn isComparable(self: Match) bool {
        return self.isInt() or
            self.isFloat() or
            (self.isVec() and self.item().isInt()) or
            (self.isVec() and self.item().isFloat());
    }

    pub fn item(self: Match) Match {
        return switch (self.info()) {
            .Pointer => |p| switch (p.size) {
                .Many, .Slice, .C => match(p.child),
                .One => match(@typeInfo(p.child).Array.child),
            },
            inline .Array, .Vector => |a| match(a.child),
            else => unreachable,
        };
    }

    pub fn isVec(self: Match) bool {
        return self.info() == .Vector;
    }

    pub fn isPtr(self: Match) bool {
        return self.info() == .Pointer and self.info().Pointer.size != .Slice;
    }

    pub fn isSlice(self: Match) bool {
        return self.info() == .Pointer and self.info().Pointer.size == .Slice;
    }

    pub fn isFunc(self: Match) bool {
        return self.info() == .Fn;
    }

    pub fn argAt(self: Match, index: usize) Match {
        return match(self.info().Fn.params[index].type.?);
    }

    pub fn isAnyTypeAt(self: Match, index: usize) bool {
        return match(self.info().Fn.params[index].is_generic);
    }

    pub fn decl(self: Match, comptime name: []const u8) Match {
        return match(@TypeOf(@field(self.type, name)));
    }

    pub fn hasFunc(self: Match, comptime name: []const u8) bool {
        return @hasDecl(self.type, name) and
            self.decl(name).isFunc();
    }

    pub fn hasMemberFunc(self: Match, comptime name: []const u8) bool {
        return @hasDecl(self.type, name) and
            self.decl(name).isFunc() and
            (self.decl(name).argAt(0).is(self.type) or
            self.decl(name).argAt(0, *self.type) or
            self.decl(name).argAt(0, *const self.type));
    }

    pub fn hasDecl(self: Match, comptime name: []const u8) bool {
        return @hasDecl(self.type, name) and
            !self.decl(name).isFunc();
    }

    pub fn field(self: Match, comptime name: []const u8) Match {
        return match(@field(self.type, name));
    }

    pub fn hasField(self: Match, comptime name: []const u8) bool {
        return @hasField(self.type, name);
    }
};

pub fn match(T: type) Match {
    return .{ .type = T };
}

test match {
    const expect = lib.assert.expect;

    try expect(match(bool).isBool());
    try expect(match(u32).isInt());
    try expect(match(f32).isFloat());
}
