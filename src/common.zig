const std = @import("std");
const lib = @import("./lib.zig");

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
                .Slice => {
                    if (left.len != right.len) {
                        return false;
                    }

                    for (left, right) |l, r| {
                        if (!equal(l, r)) {
                            return false;
                        }
                    }

                    return true;
                },
                else => return left == right,
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
