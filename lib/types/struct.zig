const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const Field = struct {
    type: type,
    name: [:0]const u8,
    default_value_ptr: ?*const anyopaque = null,
    is_comptime: bool = false,
    alignment: comptime_int = 0,

    pub fn init(Type: type, name: [:0]const u8, comptime default_value: ?Type, is_comptime: ?bool, alignment: ?comptime_int) @This() {
        if (default_value == null) {
            return .{
                .type = Type,
                .name = name,
                .default_value_ptr = null,
                .is_comptime = is_comptime orelse false,
                .alignment = alignment orelse 0,
            };
        }

        return .{
            .type = ?Type,
            .name = name,
            .default_value_ptr = @as(*const anyopaque, @ptrCast(&default_value)),
            .is_comptime = is_comptime orelse false,
            .alignment = alignment orelse 0,
        };
    }

    pub fn toBuiltin(self: @This()) lib.builtin.Type.StructField {
        return .{
            .type = self.type,
            .name = self.name,
            .default_value_ptr = self.default_value_ptr,
            .is_comptime = self.is_comptime,
            .alignment = self.alignment,
        };
    }
};

pub const StructOptions = struct {
    layout: ContainerLayout = .auto,
    /// Only valid if layout is .@"packed"
    backing_integer: ?type = null,
    decls: []const Declaration = &.{},

    pub const ContainerLayout = enum(u2) {
        auto,
        @"packed",
        @"extern",

        pub fn toBuiltin(self: @This()) lib.builtin.Type.ContainerLayout {
            return switch (self) {
                .auto => .auto,
                .@"packed" => .@"packed",
                .@"extern" => .@"extern",
            };
        }
    };

    pub const Declaration = struct {
        pub fn toBuiltin(self: @This()) lib.builtin.Type.Declaration {
            return switch (self) {
                .auto => .auto,
                .@"packed" => .@"packed",
                .@"extern" => .@"extern",
            };
        }
    };
};

pub fn Struct(comptime fields: []const Field, comptime options: StructOptions) type {
    var fields_builtin: [fields.len]lib.builtin.Type.StructField = undefined;
    for (&fields_builtin, fields) |*fb, f| {
        fb.* = f.toBuiltin();
    }

    const decls_builtin: [options.decls.len]lib.builtin.Type.Declaration = undefined;
    for (&decls_builtin, options.decls) |*db, d| {
        db.* = d.toBuiltin();
    }

    return @Type(.{ .@"struct" = .{
        .layout = options.layout.toBuiltin(),
        .backing_integer = options.backing_integer,
        .fields = &fields_builtin,
        .decls = &decls_builtin,
        .is_tuple = false,
    } });
}

test Struct {
    _ = Struct(&.{}, .{});
    _ = Struct(&.{ .{ .type = u8, .name = "foo" }, .{ .type = u8, .name = "bar" } }, .{});
    _ = Struct(&.{Field.init(u8, "foo", null, null, null)}, .{});
    _ = Struct(&.{Field.init(u8, "foo", 0, null, null)}, .{});
}

pub fn isTuple(value: type) bool {
    const Type = @typeInfo(value);

    return Type == .@"struct" and Type.@"struct".is_tuple;
}

test isTuple {
    try lib.assert.expect(isTuple(struct { u8, u8, u8 }));
    try lib.assert.expect(!isTuple(struct {}));
    try lib.assert.expect(!isTuple(struct { foo: u8 }));
    try lib.assert.expect(!isTuple([3]u8));
}

pub fn ItemOf(value: type, index: usize) type {
    const Type = @typeInfo(value);

    return Type.@"struct".fields[index].type;
}

test ItemOf {
    try lib.assert.expectEqual(ItemOf(struct { u8, i32, f64 }, 0), u8);
    try lib.assert.expectEqual(ItemOf(struct { u8, i32, f64 }, 1), i32);
    try lib.assert.expectEqual(ItemOf(struct { u8, i32, f64 }, 2), f64);
}
