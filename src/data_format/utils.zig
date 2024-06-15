const std = @import("std");
const lib = @import("../root.zig");

pub fn Block(definisions: anytype) type {
    var size_sum = 0;
    var fields: [definisions.len]std.builtin.Type.StructField = undefined;
    for (definisions, 0..) |d, i| {
        const field_name_enum, const field_type = d;

        size_sum += @bitSizeOf(field_type.value_type);
        fields[i] = .{
            .name = @tagName(field_name_enum),
            .type = field_type.value_type,
            .default_value = null,
            .is_comptime = false,
            .alignment = 0,
        };
    }

    const value_type_build = std.builtin.Type.Struct{
        .layout = .@"packed",
        .backing_integer = lib.zig.integer.Integer(.unsigned, size_sum),
        .decls = &.{},
        .fields = &fields,
        .is_tuple = false,
    };

    const ValueType = @Type(.{ .Struct = value_type_build });

    return struct {
        pub const value_type: type = ValueType;
        pub const size: ?usize = null;

        pub fn parse(bytes: []const u8) struct { value_type, usize } {
            _ = bytes;
            const value: void = {};

            return .{ value, 1 };
        }

        pub fn serialize(self: value_type, buf: []u8) []u8 {
            buf[0] = self;

            return buf[0..1];
        }
    };
}
