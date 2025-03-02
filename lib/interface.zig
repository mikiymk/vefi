const std = @import("std");
const lib = @import("root.zig");

pub const Match = struct {
    type: type,

    pub fn isInt(self: Match) bool {
        return @typeInfo(@TypeOf(self.type)) == .Int;
    }

    pub fn isFloat(self: Match) bool {
        return @typeInfo(@TypeOf(self.type)) == .Float;
    }

    pub fn isNum(self: Match) bool {
        return self.isInt() or self.isFloat();
    }

    pub isFunc(self: Match) bool {
        return @typeInfo(@TypeOf(self.type)) == .Fn;
    }

    pub fn decl(self: Match, comptime name: []const u8) Match {
        return match(@field(self.type, name));
    }

    pub fn hasFunc(self: Match, comptime name: []const u8) bool {
        return @hasDecl(self.type, name) and
            self.decl(name).isFunc();
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
