const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const Field = struct {
    type: type,
    default_value: ?*const anyopaque = null,
    is_comptime: bool = false,
    alignment: comptime_int = 0,

    pub fn init(Type: type, comptime default_value: ?Type, is_comptime: ?bool, alignment: ?comptime_int) @This() {
        if (default_value == null) {
            return .{
                .type = Type,
                .default_value = null,
                .is_comptime = is_comptime orelse false,
                .alignment = alignment orelse 0,
            };
        }

        return .{
            .type = ?Type,
            .default_value = @as(*const anyopaque, @ptrCast(&default_value)),
            .is_comptime = is_comptime orelse false,
            .alignment = alignment orelse 0,
        };
    }

    pub fn toBuiltin(self: @This(), comptime index: usize) lib.builtin.Type.StructField {
        return .{
            .type = self.type,
            .name = &lib.types.Integer.toStringComptime(index, 10),
            .default_value = self.default_value,
            .is_comptime = self.is_comptime,
            .alignment = self.alignment,
        };
    }
};

pub const TupleOptions = struct {
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

pub fn Tuple(comptime fields: []const Field, comptime options: TupleOptions) type {
    var fields_builtin: [fields.len]lib.builtin.Type.StructField = undefined;
    for (&fields_builtin, fields, 0..) |*fb, f, i| {
        fb.* = f.toBuiltin(i);
    }

    const decls_builtin: [options.decls.len]lib.builtin.Type.Declaration = undefined;
    for (&decls_builtin, options.decls) |*db, d| {
        db.* = d.toBuiltin();
    }

    return @Type(.{ .Struct = .{
        .layout = options.layout.toBuiltin(),
        .backing_integer = options.backing_integer,
        .fields = &fields_builtin,
        .decls = &decls_builtin,
        .is_tuple = true,
    } });
}

test Tuple {
    _ = Tuple(&.{}, .{});
    _ = Tuple(&.{ .{ .type = u8 }, .{ .type = u8 } }, .{});
    _ = Tuple(&.{Field.init(u8, null, null, null)}, .{});
    _ = Tuple(&.{Field.init(u8, 0, null, null)}, .{});
}

pub fn isTuple(value: type) bool {
    const Type = @typeInfo(value);

    return Type == .Struct and Type.Struct.is_tuple;
}

test isTuple {
    try lib.assert.expect(isTuple(struct { u8, u8, u8 }));
    try lib.assert.expect(!isTuple(struct {}));
    try lib.assert.expect(!isTuple(struct { foo: u8 }));
    try lib.assert.expect(!isTuple([3]u8));
}

pub fn ItemOf(value: type, index: usize) type {
    const Type = @typeInfo(value);

    return Type.Struct.fields[index].type;
}

test ItemOf {
    try lib.assert.expectEqual(ItemOf(struct { u8, i32, f64 }, 0), u8);
    try lib.assert.expectEqual(ItemOf(struct { u8, i32, f64 }, 1), i32);
    try lib.assert.expectEqual(ItemOf(struct { u8, i32, f64 }, 2), f64);
}
