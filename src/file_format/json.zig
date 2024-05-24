//!
//!

const lib = @import("../lib.zig");
const hash_map = lib.collection.hash_map;

pub const JsonType = union(enum) {
    null: void,
    boolean: bool,
    number: f64,
    string: []u8,

    array: []JsonType,
    object: hash_map.Map([]u8, JsonType),
};
