//! 標準ライブラリっぽいものを作ってみる
//! 参考
//! zig https://ziglang.org/documentation/master/std/
//! java https://docs.oracle.com/javase/jp/21/docs/api/index.html
//! python https://docs.python.org/ja/3/library/index.html
//! c++ https://cpprefjp.github.io/reference.html
//! rust https://doc.rust-lang.org/std/
//! go https://pkg.go.dev/std
//! ruby https://docs.ruby-lang.org/ja/latest/doc/index.html
//! php https://www.php.net/manual/ja/funcref.php

const std = @import("std");

pub const primitive = struct {
    pub const boolean = struct {};
    pub const character = struct {};
    pub const integer = @import("primitive/integer.zig");
    pub const float = struct {};

    pub const optional = @import("primitive/optional.zig");
};

pub const collection = struct {
    pub const dynamic_array = @import("collection/dynamic_array.zig");

    pub const list = @import("collection/list.zig");
    pub const doubly_list = struct {};
    pub const circular_list = struct {};

    pub const stack = struct {};
    pub const queue = struct {};
    pub const priority_queue = struct {};
    pub const double_ended_queue = struct {};

    pub const tree = struct {};
    pub const heap = struct {};

    pub const hash_map = @import("collection/hash_map.zig");
    pub const tree_map = struct {};
    pub const bidirectional_map = struct {};
    pub const ordered_map = struct {};

    pub const bit_array = struct {};
};

pub const math = struct {
    pub const integer = struct {};
    pub const ratio = struct {};
    pub const float = struct {};
    pub const complex = struct {};
};

pub const string = struct {
    pub const utf8_string = struct {};
    pub const ascii_string = struct {};
};

pub const datetime = struct {
    pub const date = struct {};
    pub const time = struct {};

    pub const timezone = struct {};
};

pub const input_output = struct {};
pub const file_system = struct {};
pub const network = struct {};
pub const memory = struct {};
pub const regular_expression = struct {};
pub const graphic = struct {};
pub const types = struct {
    pub fn typeName(comptime T: type) []const u8 {
        return @typeName(T);
    }
};
pub const random = struct {};
pub const locale = struct {};
pub const file_format = struct {
    pub const joint_photographic_experts_group = @import("file_format/joint_photographic_experts_group.zig");
    pub const portable_network_graphics = @import("file_format/portable_network_graphics.zig");
};
pub const computer_language = struct {
    pub const json = @import("computer_language/json.zig");
};
pub const natural_language = struct {};
pub const assert = struct {
    pub fn assert(ok: bool) void {
        if (!ok) {
            unreachable;
        }
    }

    pub fn assertStatic(comptime ok: bool) void {
        if (!ok) {
            @compileError("assertion failed");
        }
    }
};
pub const testing = struct {
    pub fn expect(ok: bool) error{AssertionFailed}!void {
        if (!ok) {
            return error.AssertionFailed;
        }
    }

    fn equal(left: anytype, right: @TypeOf(left)) bool {
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
            else => return left == right,
        }
    }

    pub fn expectEqual(left: anytype, right: @TypeOf(left)) error{AssertionFailed}!void {
        if (!equal(left, right)) {
            std.debug.print("left: {!} != right: {!}\n", .{ left, right });

            return error.AssertionFailed;
        }
    }
};

test {
    // std.testing.refAllDeclsRecursive(@This());

    _ = primitive.boolean;
    _ = primitive.character;
    _ = primitive.integer;
    _ = primitive.float;
    _ = primitive.optional;

    _ = collection.dynamic_array;
    _ = collection.list;

    _ = computer_language.json;
}
