const std = @import("std");
const lib = @import("../root.zig");

const Match = @This();

type: type,

pub fn init(T: type) Match {
    return .{ .type = T };
}

fn info(self: @This()) std.builtin.Type {
    return @typeInfo(self.type);
}

pub fn is(self: @This(), target: type) bool {
    return self.type == target;
}

/// 整数
pub fn isInt(self: @This()) bool {
    return self.info() == .int or self.info() == .comptime_int;
}

/// 符号付き整数
pub fn isSigned(self: @This()) bool {
    return self.info() == .int and self.info().int.signedness == .signed;
}

/// 符号なし整数
pub fn isUnsigned(self: @This()) bool {
    return self.info() == .int and self.info().int.signedness == .unsigned;
}

/// 浮動小数点数
pub fn isFloat(self: @This()) bool {
    return self.info() == .float or self.info() == .comptime_float;
}

/// 整数か浮動小数点数
pub fn isNum(self: @This()) bool {
    return self.isInt() or self.isFloat();
}

/// `==` `!=`で比較可能
pub fn isEqualed(self: @This()) bool {
    return self.is(type) or
        self.is(bool) or
        self.isNum() or
        self.isPtr() or
        self.isEnum() or
        // TODO: ↓ほんと？
        self.isVec();
}

/// `<` `<=` `>` `>=`で比較可能
pub fn isOrdered(self: Match) bool {
    return self.isNum() or
        (self.isVec() and self.item().isNum());
}

/// 複合型の内容のマッチオブジェクト
pub fn item(self: Match) Match {
    return switch (self.info()) {
        inline .pointer, .array, .vector, .optional => |a| init(a.child),
        .error_union => |e| init(e.payload),
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
        .error_union => |e| init(e.error_set),
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
    return init(self.info().@"fn".params[index].type.?);
}

pub fn isAnyTypeAt(self: Match, index: usize) bool {
    return init(self.info().@"fn".params[index].is_generic);
}

pub fn returns(self: Match) Match {
    return init(self.info().@"fn".return_type.?);
}

pub fn decl(self: Match, comptime name: []const u8) Match {
    return init(@TypeOf(@field(self.type, name)));
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
    return init(@TypeOf(@field(value, name)));
}

pub fn hasField(self: Match, comptime name: []const u8) bool {
    return @hasField(self.type, name);
}

test init {
    const expect = lib.assert.expect;

    try expect(init(bool).is(bool));
    try expect(init(u32).isInt());
    try expect(init(i16).isSigned());
    try expect(init(u16).isUnsigned());
    try expect(init(f32).isFloat());
    try expect(init(type).isComparable());
    try expect(init(@Vector(8, u8)).isOrdered());
    try expect(init([2]f64).isArray());
    try expect(init([2]f64).item().is(f64));
    try expect(init(@Vector(5, bool)).isVec());
    try expect(init(@Vector(5, bool)).item().is(bool));
    try expect(init(*const bool).isPtr());
    try expect(init(*const bool).item().is(bool));
    try expect(init([]const bool).isSlice());
    try expect(init([]const bool).item().is(bool));
    try expect(init(enum { faa, fee, foo }).isUserDefined());
    try expect(init(packed struct { a: u8 }).isPacked());
    try expect(init(extern struct { a: c_int }).isExtern());
    try expect(init(struct { a: f16 }).isStruct());
    try expect(init(enum { a, b, c }).isEnum());
    try expect(init(union { a: u1, b: u2, c: u3 }).isUnion());
    try expect(init(opaque {}).isOpaque());
    try expect(init(?u8).isOptional());
    try expect(init(?u8).item().is(u8));
    try expect(init(error{ A, B }!u32).isErrorUnion());
    try expect(init(error{ A, B }!u32).item().is(u32));
    try expect(init(error{ A, B }!u32).errorSet().is(error{ A, B }));
    try expect(init(error{ A, B }).isErrorSet());
    try expect(init(error{ A, B }!u32).hasError("A"));
    try expect(init(error{ A, B }).hasError("B"));
    try expect(init(fn (u8, f32, bool) void).isFn());
    try expect(init(fn (u8, f32, bool) void).argAt(0).is(u8));
    try expect(init(fn (u8, f32, bool) void).returns().is(void));

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

    try expect(init(T).decl("bar").is(i32));
    try expect(init(T).hasFn("getBar"));
    try expect(init(T).hasMethod("getFoo"));
    try expect(init(T).hasDecl("bar"));
    try expect(init(T).field("foo").is(u32));
    try expect(init(T).hasField("foo"));
}
