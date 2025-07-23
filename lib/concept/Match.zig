//! 型の情報を確認する関数

const std = @import("std");
const lib = @import("../root.zig");

type: type,

/// 無効な型(要素のない型の要素を取り出した場合など)に使う
const invalid = struct {};

pub fn init(T: type) @This() {
    return .{ .type = T };
}

fn info(self: @This()) std.builtin.Type {
    return @typeInfo(self.type);
}

/// 指定された型
pub fn is(self: @This(), target: type) bool {
    return self.type == target;
}

/// 整数
pub fn isInt(self: @This()) bool {
    return self.info() == .int or
        self.is(comptime_int);
}

/// 符号付き整数
pub fn isSigned(self: @This()) bool {
    return self.info() == .int and
        self.info().int.signedness == .signed;
}

/// 符号なし整数
pub fn isUnsigned(self: @This()) bool {
    return self.info() == .int and
        self.info().int.signedness == .unsigned;
}

/// 浮動小数点数
pub fn isFloat(self: @This()) bool {
    return self.info() == .float or
        self.is(comptime_float);
}

/// 指定したビット数
pub fn isBitOf(self: @This(), size: u15) bool {
    return !self.is(invalid) and
        @bitSizeOf(self.type) == size;
}

/// 整数か浮動小数点数
pub fn isNum(self: @This()) bool {
    return self.isInt() or self.isFloat();
}

/// 配列
pub fn isArray(self: @This()) bool {
    return self.info() == .array;
}

/// ベクトル
pub fn isVec(self: @This()) bool {
    return self.info() == .vector;
}

/// スライスではないポインタ
pub fn isPtr(self: @This()) bool {
    return self.info() == .pointer and
        self.info().pointer.size != .slice;
}

/// スライス
pub fn isSlice(self: @This()) bool {
    return self.info() == .pointer and
        self.info().pointer.size == .slice;
}

/// 構造体
pub fn isStruct(self: @This()) bool {
    return !self.is(invalid) and
        self.info() == .@"struct" and
        !self.info().@"struct".is_tuple;
}

/// タプル
pub fn isTuple(self: @This()) bool {
    return self.info() == .@"struct" and
        self.info().@"struct".is_tuple;
}

/// 列挙型
pub fn isEnum(self: @This()) bool {
    return self.info() == .@"enum";
}

/// 合併型
pub fn isUnion(self: @This()) bool {
    return self.info() == .@"union";
}

/// 不透明型
pub fn isOpaque(self: @This()) bool {
    return self.info() == .@"opaque";
}

/// `packed`
pub fn isPacked(self: @This()) bool {
    return switch (self.info()) {
        inline .@"struct", .@"union" => |s| s.layout == .@"packed",
        else => false,
    };
}

/// `extern`
pub fn isExtern(self: @This()) bool {
    return switch (self.info()) {
        inline .@"struct", .@"union" => |s| s.layout == .@"extern",
        else => false,
    };
}

/// オプショナル
pub fn isOptional(self: @This()) bool {
    return self.info() == .optional;
}

/// エラー合併型
pub fn isErrorUnion(self: @This()) bool {
    return self.info() == .error_union;
}

/// エラー集合型
pub fn isErrorSet(self: @This()) bool {
    return self.info() == .error_set;
}

/// 特定の名前のエラーを受け入れるか
pub fn hasError(self: @This(), comptime name: []const u8) bool {
    if (self.isErrorUnion()) {
        return self.errorSet().hasError(name);
    } else if (self.isErrorSet()) {
        for (self.info().error_set) |err| {
            if (err.name.len != name.len) continue;
            for (err.name, name) |en, n| {
                if (en != n) break;
            } else return true;
        }
    }

    return false;
}

/// 関数
pub fn isFn(self: @This()) bool {
    return self.info() == .@"fn";
}

/// n番目の引数の型が`anytype`か
pub fn isAnyTypeAt(self: @This(), index: usize) bool {
    return self.isFn() and
        index < self.info().@"fn".params.len and
        self.info().@"fn".params[index].is_generic;
}

/// 指定した名前の関数を持つか
pub fn hasFn(self: @This(), comptime name: []const u8) bool {
    return @hasDecl(self.type, name) and
        self.decl(name).isFn();
}

/// 指定した名前のメソッド(a.b()として呼びだせる関数)を持つか
pub fn hasMethod(self: @This(), comptime name: []const u8) bool {
    return self.hasFn(name) and
        (self.decl(name).argAt(0).is(self.type) or
            ((self.decl(name).argAt(0).isPtr()) and
                self.decl(name).argAt(0).item().is(self.type)));
}

/// 指定した名前の関数でない値を持つか
pub fn hasDecl(self: @This(), comptime name: []const u8) bool {
    return @hasDecl(self.type, name) and
        !self.decl(name).isFn();
}

/// 指定した名前でフィールドを持つか
pub fn hasField(self: @This(), comptime name: []const u8) bool {
    return @hasField(self.type, name);
}

/// `==` `!=`で比較可能
pub fn isEqualed(self: @This()) bool {
    return self.is(type) or
        self.is(bool) or
        self.isNum() or
        self.isPtr() or
        self.isEnum() or
        self.isVec();
}

/// `<` `<=` `>` `>=`で比較可能
pub fn isOrdered(self: @This()) bool {
    return self.isNum() or (self.isVec() and self.item().isNum());
}

/// 添字アクセス可能
pub fn isIndexAccess(self: @This()) bool {
    return self.isArray() or
        self.isVec() or
        self.isTuple() or
        (self.isPtr() and
            (self.info().pointer.size == .many or
                self.info().pointer.size == .c or
                self.item().isArray() or
                self.item().isVec() or
                self.item().isTuple())) or
        self.isSlice();
}

/// スライス化可能
pub fn isSliceAccess(self: @This()) bool {
    return self.isArray() or
        self.isPtr() or
        self.isSlice();
}

/// ユーザー定義型
pub fn isUserDefined(self: @This()) bool {
    return !self.is(invalid) and (
        self.isStruct() or
        self.isEnum() or
        self.isUnion() or
        self.isOpaque()
    );
}

/// コンパイル時にサイズが決まる
pub fn isSized(self: @This()) bool {
    return !self.is(invalid) and
        !self.isOpaque() and
        self.type != anyopaque;
}

/// 複合型の内容のマッチオブジェクト
pub fn item(self: @This()) @This() {
    return switch (self.info()) {
        inline .pointer, .array, .vector, .optional => |a| init(a.child),
        .error_union => |e| init(e.payload),
        else => init(invalid),
    };
}

/// エラー合併型からエラー集合型を取り出す
pub fn errorSet(self: @This()) @This() {
    return switch (self.info()) {
        .error_union => |e| init(e.error_set),
        else => init(invalid),
    };
}

/// n番目の引数の型
pub fn argAt(self: @This(), index: usize) @This() {
    switch (self.info()) {
        .@"fn" => |f| if (index < f.params.len)
            if (f.params.type) |t|
                return init(t),
        else => {},
    };
    return init(invalid);
}

/// 戻り値の型
pub fn returns(self: @This()) @This() {
    switch (self.info()) {
        .@"fn" => |f| if (f.return_type) |t|
            return init(t),
        else => {},
    };
    return init(invalid);
}

/// 型の中で定義された値
pub fn decl(self: @This(), comptime name: []const u8) @This() {
    if (@hasDecl(self.type, name)) 
        return init(@TypeOf(@field(self.type, name)));
    else
        return init(invalid);
}

/// フィールドの型
pub fn field(self: @This(), comptime name: []const u8) @This() {
    const value: self.type = undefined;
    if (self.hasField(name)) 
        return init(@TypeOf(@field(value, name)));
    else
        return init(invalid);
}

test init {
    const expect = lib.assert.expect;

    try expect(init(bool).is(bool));
    try expect(init(*u32).is(*u32));
    try expect(init(?f16).is(?f16));

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
