const std = @import("std");
const lib = @import("root.zig");

test {
    std.testing.refAllDecls(@This());
}

pub fn equal(left: anytype, right: @TypeOf(left)) bool {
    const info = @typeInfo(@TypeOf(left));

    switch (info) {
        .Optional => {
            if (left == null and right == null) {
                return true;
            } else if (left == null or right == null) {
                return false;
            } else {
                return equal(left.?, right.?);
            }
        },
        .ErrorUnion => return equalErrorUnion(left, right),
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
                .Slice => return lib.types.Slice.equal(p.child, left, right),
                .One => {
                    const child_info = @typeInfo(p.child);
                    switch (child_info) {
                        .Array => |a| { // *[n]T as []T
                            return lib.types.Slice.equal(a.child, left, right);
                        },
                        else => {},
                    }
                },
                else => {},
            }

            return left == right;
        },
        .Vector => return @reduce(.And, left == right),
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
                else => return equal(left_info, right_info),
            }
        },

        else => return left == right,
    }
}

pub fn equalErrorUnion(left: anytype, right: @TypeOf(left)) bool {
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
}

pub fn compare(T: type) fn (left: T, right: T) lib.math.Order {
    return struct {
        pub fn f(left: T, right: T) lib.math.Order {
            const info = @typeInfo(T);

            switch (info) {
                .Int, .Float, .ComptimeInt, .ComptimeFloat => return lib.math.compare(left, right),

                else => return left.compare(right),
            }
        }
    }.f;
}
