const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const This = struct {};
pub const AnyType = struct {};
pub const InterfaceOptions = struct {
    fields: []const Declaration = &.{},
    declarations: []const Declaration = &.{},

    pub const Declaration = struct {
        name: []const u8,
        type: type,
    };
};

pub fn Interface(options: InterfaceOptions) type {
    return struct {
        fn ReplaceThis(T: type, DeclType: type) type {
            switch (@typeInfo(DeclType)) {
                .Fn => |info| {
                    var new_params: [info.params.len]std.builtin.Type.Fn.Param = undefined;

                    for (info.params, &new_params) |p, *np| {
                        np.* = .{
                            .is_generic = p.is_generic,
                            .is_noalias = p.is_noalias,
                            .type = if (p.type == This) T else p.type,
                        };
                    }

                    return @Type(.{ .Fn = .{
                        .is_generic = info.is_generic,
                        .is_var_args = info.is_var_args,
                        .params = &new_params,
                        .return_type = if (info.return_type == This) T else info.return_type,
                        .calling_convention = info.calling_convention,
                    } });
                },
                else => return DeclType,
            }
        }

        pub fn isImplements(T: type) bool {
            const dummy: T = undefined;
            inline for (options.fields) |f| {
                if (!@hasField(T, f.name)) {
                    return false;
                }

                const field_type = @TypeOf(@field(dummy, f.name));
                if (field_type == AnyType) {
                    continue;
                }
                if (!lib.common.equal(field_type, ReplaceThis(T, f.type))) {
                    return false;
                }
            }

            inline for (options.declarations) |d| {
                if (!@hasDecl(T, d.name)) {
                    return false;
                }

                const field_type = @TypeOf(@field(T, d.name));
                if (field_type == AnyType) {
                    continue;
                }
                if (!lib.common.equal(field_type, ReplaceThis(T, d.type))) {
                    return false;
                }
            }

            return true;
        }
    };
}

test Interface {
    const IteratorInterface = Interface(.{
        .fields = &.{
            .{ .name = "foo", .type = u8 },
        },
        .declarations = &.{
            .{ .name = "bar", .type = u16 },
            .{ .name = "get", .type = fn () u32 },
            .{ .name = "next", .type = fn (This) u32 },
        },
    });

    const Iterator_01 = struct {
        foo: u8,

        pub const bar: u16 = 5;
        pub fn get() u32 {
            return 6;
        }
        pub fn next(_: @This()) u32 {
            return 6;
        }
    };
    const Iterator_02 = struct {
        foz: u8,

        pub const bar: u16 = 5;
        pub fn get() u32 {
            return 6;
        }
        pub fn next(_: @This()) u32 {
            return 6;
        }
    };
    const Iterator_03 = struct {
        foo: u8,

        pub const baz: u16 = 5;
        pub fn get() u32 {
            return 6;
        }
        pub fn next(_: @This()) u32 {
            return 6;
        }
    };
    const Iterator_04 = struct {
        foo: u8,

        pub const bar: u16 = 5;
        pub fn getz() u32 {
            return 6;
        }
        pub fn next(_: @This()) u32 {
            return 6;
        }
    };
    const Iterator_05 = struct {
        foo: u8,

        pub const bar: u16 = 5;
        pub fn get() u32 {
            return 6;
        }
        pub fn nextz(_: @This()) u32 {
            return 6;
        }
    };

    try lib.assert.expect(IteratorInterface.isImplements(Iterator_01));
    try lib.assert.expect(!IteratorInterface.isImplements(Iterator_02));
    try lib.assert.expect(!IteratorInterface.isImplements(Iterator_03));
    try lib.assert.expect(!IteratorInterface.isImplements(Iterator_04));
    try lib.assert.expect(!IteratorInterface.isImplements(Iterator_05));
}
