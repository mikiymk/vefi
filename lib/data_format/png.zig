//! PNG (Portable Network Graphics)
//! https://www.w3.org/TR/png-3/
//! https://datatracker.ietf.org/doc/html/rfc2083

const std = @import("std");
const lib = @import("../root.zig");

pub const signature: [8]u8 = .{ 89 50 4E 47 0D 0A 1A 0A };

pub const Chunk = struct {
    length: u32,
    chunk_type: [4]u8,
    chunk_data: []u8,
    crc: [4]u8,

    pub fn parse(r: Reader) Chunk {
        var chunk: Chunk = undefined;
        chunk.length = r.read(u32);
        chunk.chunk_type = r.read(4);
        chunk.chunk_data = r.read(chunk.length);
        chunk.crc = r.read(4);
        return chunk;
    }
};
