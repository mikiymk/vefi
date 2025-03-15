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
        return self.info() == .int or self.info() == .comptime_int;
    }

    pub fn isSigned(self: Match) bool {
        return self.info() == .int and self.info().int.signedness == .signed;
    }

    pub fn isUnsigned(self: Match) bool {
        return self.info() == .int and self.info().int.signedness == .unsigned;
    }

    pub fn isFloat(self: Match) bool {
        return self.info() == .float or self.info() == .comptime_float;
    }

    pub fn isNum(self: Match) bool {
        return self.isInt() or self.isFloat();
    }

    /// `==` `!=`で比較可能
    pub fn isComparable(self: Match) bool {
        return self.is(type) or
            self.is(bool) or
            self.isInt() or
            self.isFloat() or
            self.isPtr() or
            self.isEnum() or
            self.isVec();
    }

    /// `<` `<=` `>` `>=`で比較可能
    pub fn isOrdered(self: Match) bool {
        return self.isInt() or
            self.isFloat() or
            (self.isVec() and
                (self.item().isInt() or
                    self.item().isFloat()));
    }

    pub fn item(self: Match) Match {
        return switch (self.info()) {
            inline .pointer, .array, .vector, .optional => |a| match(a.child),
            .error_union => |e| match(e.payload),
            else => @panic(@typeName(self.type) ++ " have no items."),
        };
    }

    pub fn isArray(self: Match) bool {
        return self.info() == .array;
    }

    pub fn isVec(self: Match) bool {
        return self.info() == .vector;
    }

    pub fn isPtr(self: Match) bool {
        return self.info() == .pointer and self.info().pointer.size != .slice;
    }

    pub fn isSlice(self: Match) bool {
        return self.info() == .pointer and self.info().pointer.size == .slice;
    }

    pub fn isUserDefined(self: Match) bool {
        return self.isStruct() or self.isEnum() or self.isUnion();
    }

    pub fn isPacked(self: Match) bool {
        return switch (self.info()) {
            inline .@"struct", .@"union" => |s| s.layout == .@"packed",
            else => false,
        };
    }

    pub fn isExtern(self: Match) bool {
        return switch (self.info()) {
            inline .@"struct", .@"union" => |s| s.layout == .@"extern",
            else => false,
        };
    }

    pub fn isStruct(self: Match) bool {
        return self.info() == .@"struct";
    }

    pub fn isEnum(self: Match) bool {
        return self.info() == .@"enum";
    }

    pub fn isUnion(self: Match) bool {
        return self.info() == .@"union";
    }

    pub fn isOpaque(self: Match) bool {
        return self.info() == .@"opaque";
    }

    pub fn isOptional(self: Match) bool {
        return self.info() == .optional;
    }

    pub fn isErrorUnion(self: Match) bool {
        return self.info() == .error_union;
    }

    pub fn errorSet(self: Match) Match {
        return switch (self.info()) {
            .error_union => |e| match(e.error_set),
            else => @panic(@typeName(self.type) ++ " is not error union."),
        };
    }

    pub fn isErrorSet(self: Match) bool {
        return self.info() == .error_set;
    }

    pub fn hasError(self: Match, comptime name: []const u8) bool {
        if (comptime self.isErrorUnion())
            return self.errorSet().hasError(name);

        if (self.info().error_set) |set| {
            for (set) |err| {
                if (err.name.len != name.len) continue;
                for (err.name, name) |en, n| {
                    if (en != n) break;
                } else return true;
            }
        }

        return false;
    }

    pub fn isFn(self: Match) bool {
        return self.info() == .@"fn";
    }

    pub fn argAt(self: Match, index: usize) Match {
        return match(self.info().@"fn".params[index].type.?);
    }

    pub fn isAnyTypeAt(self: Match, index: usize) bool {
        return match(self.info().@"fn".params[index].is_generic);
    }

    pub fn returns(self: Match) Match {
        return match(self.info().@"fn".return_type.?);
    }

    pub fn decl(self: Match, comptime name: []const u8) Match {
        return match(@TypeOf(@field(self.type, name)));
    }

    pub fn hasFn(self: Match, comptime name: []const u8) bool {
        return @hasDecl(self.type, name) and
            self.decl(name).isFn();
    }

    /// その型の値がa.b()として呼びだせるもの
    pub fn hasMethod(self: Match, comptime name: []const u8) bool {
        return self.hasFn(name) and
            (self.decl(name).argAt(0).is(self.type) or
                ((comptime self.decl(name).argAt(0).isPtr()) and // comptimeでないと下の.item()でコンパイルエラー
                    self.decl(name).argAt(0).item().is(self.type)));
    }

    pub fn hasDecl(self: Match, comptime name: []const u8) bool {
        return @hasDecl(self.type, name) and
            !self.decl(name).isFn();
    }

    pub fn field(self: Match, comptime name: []const u8) Match {
        const value: self.type = undefined;
        return match(@TypeOf(@field(value, name)));
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

    try expect(match(bool).is(bool));
    try expect(match(u32).isInt());
    try expect(match(i16).isSigned());
    try expect(match(u16).isUnsigned());
    try expect(match(f32).isFloat());
    try expect(match(type).isComparable());
    try expect(match(@Vector(8, u8)).isOrdered());
    try expect(match([2]f64).isArray());
    try expect(match([2]f64).item().is(f64));
    try expect(match(@Vector(5, bool)).isVec());
    try expect(match(@Vector(5, bool)).item().is(bool));
    try expect(match(*const bool).isPtr());
    try expect(match(*const bool).item().is(bool));
    try expect(match([]const bool).isSlice());
    try expect(match([]const bool).item().is(bool));
    try expect(match(enum { faa, fee, foo }).isUserDefined());
    try expect(match(packed struct { a: u8 }).isPacked());
    try expect(match(extern struct { a: c_int }).isExtern());
    try expect(match(struct { a: f16 }).isStruct());
    try expect(match(enum { a, b, c }).isEnum());
    try expect(match(union { a: u1, b: u2, c: u3 }).isUnion());
    try expect(match(opaque {}).isOpaque());
    try expect(match(?u8).isOptional());
    try expect(match(?u8).item().is(u8));
    try expect(match(error{ A, B }!u32).isErrorUnion());
    try expect(match(error{ A, B }!u32).item().is(u32));
    try expect(match(error{ A, B }!u32).errorSet().is(error{ A, B }));
    try expect(match(error{ A, B }).isErrorSet());
    try expect(match(error{ A, B }!u32).hasError("A"));
    try expect(match(error{ A, B }).hasError("B"));
    try expect(match(fn (u8, f32, bool) void).isFn());
    try expect(match(fn (u8, f32, bool) void).argAt(0).is(u8));
    try expect(match(fn (u8, f32, bool) void).returns().is(void));

    const T = struct {
        foo: u32,

        const bar: i32 = 999;

        fn getFoo(self: @This()) u32 {
            return self.foo;
        }

        fn getBar() i32 {
            return bar;
        }
    };

    try expect(match(T).decl("bar").is(i32));
    try expect(match(T).hasFn("getBar"));
    try expect(match(T).hasMethod("getFoo"));
    try expect(match(T).hasDecl("bar"));
    try expect(match(T).field("foo").is(u32));
    try expect(match(T).hasField("foo"));
}
