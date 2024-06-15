//! zigのtype型

const std = @import("std");
const lib = @import("../root.zig");

/// 型をわかりやすい文字列に変換する。
pub fn toString(T: type) []const u8 {
    const info = @typeInfo(T);

    switch (info) {
        .Int => |x| {
            const sign_char: u8 = switch (x.signedness) {
                .signed => 'i',
                .unsigned => 'u',
            };

            return std.fmt.comptimePrint("{c}{d}", .{ sign_char, x.bits });
        },
        .Struct => |x| {
            comptime var a: []const u8 = "struct {";

            switch (x.layout) {
                .@"extern" => {
                    a = "extern struct {";
                },
                .@"packed" => {
                    a = "packed struct {";
                },
                else => {},
            }

            comptime var is_first = true;
            inline for (x.fields) |f| {
                if (!is_first) {
                    a = a ++ ",";
                }

                if (x.is_tuple) {
                    a = a ++ std.fmt.comptimePrint(" {s}", .{comptime toString(f.type)});
                } else {
                    a = a ++ std.fmt.comptimePrint(" {s}{s}", .{ f.name, toString(f.type) });
                }

                is_first = false;
            }

            a = a ++ " }";
            return a;
        },
        else => {
            // TODO
            @panic(std.fmt.comptimePrint("not implemented {}", .{info}));
        },
    }
}
