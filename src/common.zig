const std = @import("std");
const lib = @import("root.zig");

pub fn equal(left: anytype, right: @TypeOf(left)) bool {
    const info = @typeInfo(@TypeOf(left));

    switch (info) {
        .ErrorUnion => {
            if (left) |l| {
                if (right) |r| {
                    return equal(l, r);
                } else |_| {}
            } else |e| {
                _ = right catch |f| {
                    return e == f;
                };
            }

            return false;
        },
        .Struct => |s| {
            inline for (s.fields) |field| {
                const field_name = field.name;
                const field_left = @field(left, field_name);
                const field_right = @field(right, field_name);

                if (!equal(field_left, field_right)) {
                    return false;
                }
            }

            return true;
        },
        .Union => {
            if (@intFromEnum(left) != @intFromEnum(right)) {
                return false;
            }

            const tag_name = @tagName(left);

            return equal(@field(left, tag_name), @field(right, tag_name));
        },
        .Array => {
            for (left, right) |l, r| {
                if (!equal(l, r)) {
                    return false;
                }
            }

            return true;
        },
        .Pointer => |p| {
            switch (p.size) {
                .Slice => return lib.types.Slice.equal(left, right),
                else => return left == right,
            }
        },
        .Type => {
            if (left == right) {
                return true;
            }

            const left_info = @typeInfo(left);
            const right_info = @typeInfo(right);

            switch (left_info) {
                .Struct => |l| {
                    switch (right_info) {
                        .Struct => |r| {
                            if (!l.is_tuple or !r.is_tuple) {
                                return false;
                            }

                            if (l.layout != r.layout or
                                l.backing_integer != r.backing_integer or
                                l.fields.len != r.fields.len or
                                l.decls.len != r.decls.len or
                                l.is_tuple != r.is_tuple)
                            {
                                return false;
                            }

                            inline for (l.fields, r.fields) |lf, rf| {
                                if (!equal(lf.type, rf.type) or
                                    !equal(lf.name, rf.name))
                                {
                                    return false;
                                }
                            }

                            for (l.decls, r.decls) |ld, rd| {
                                if (!equal(ld.type, rd.type) or
                                    !equal(ld.name, rd.name))
                                {
                                    return false;
                                }
                            }

                            return true;
                        },
                        else => return false,
                    }
                },
                else => return left_info == right_info,
            }
        },

        else => return left == right,
    }
}

pub const Order = enum {
    equal,
    greater_than,
    less_than,
};

test {
    std.testing.refAllDecls(@This());
}
