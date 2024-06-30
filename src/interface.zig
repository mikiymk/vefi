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
        fn implements(T: type, Decl: ?type, If: ?type) bool {
            if (Decl == null and If == null) {
                return true;
            } else if (Decl == null) {
                return false;
            } else if (If == null) {
                return false;
            }

            const UDecl = Decl.?;
            const UIf = If.?;

            if (UIf == AnyType) {
                return true;
            }
            if (UIf == This) {
                return UDecl == T;
            }
            if (UDecl == UIf) {
                return true;
            }

            switch (@typeInfo(UDecl)) {
                .Fn => |info| {
                    const interface_fn = @typeInfo(UIf).Fn;

                    inline for (info.params, interface_fn.params) |p, ip| {
                        if (!implements(T, p.type, ip.type)) {
                            return false;
                        }
                    }

                    if (!implements(T, info.return_type, interface_fn.return_type)) {
                        return false;
                    }

                    return true;
                },
                .Struct => {
                    const interface_struct = @typeInfo(UIf).Struct;

                    const dummy: UDecl = undefined;
                    inline for (interface_struct.fields) |f| {
                        const field_type = @TypeOf(@field(dummy, f.name));
                        if (!implements(T, field_type, f.type)) {
                            return false;
                        }
                    }

                    return true;
                },
                .Pointer => |info| {
                    const interface_pointer = @typeInfo(UIf).Pointer;
                    return implements(T, info.child, interface_pointer.child);
                },
                else => {},
            }

            @panic("unknown type " ++ @typeName(UDecl));
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
                if (!implements(T, field_type, f.type)) {
                    return false;
                }
            }

            inline for (options.declarations) |d| {
                if (!@hasDecl(T, d.name)) {
                    return false;
                }

                const field_type = @TypeOf(@field(T, d.name));
                if (!implements(T, field_type, d.type)) {
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
