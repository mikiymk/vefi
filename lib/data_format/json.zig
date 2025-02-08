//! JSON (JavaScript Object Notation)
//! https://ecma-international.org/publications-and-standards/standards/ecma-404/

const std = @import("std");
const lib = @import("../root.zig");

test {
    std.testing.refAllDecls(@This());
}

const hash_map = lib.collection.hash_map;

pub const JsonType = union(enum) {
    null: void,
    boolean: bool,
    number: f64,
    string: []u8,

    array: []JsonType,
    object: hash_map.Map([]u8, JsonType),
};
