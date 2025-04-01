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

/// 画像ヘッダー
pub const ImageHeader = struct {
    pub const chunk_type = "IHDR";

    width: u32,
    height: u32,
    bit_depth: u8,
    color_type: u8,
    compression_method: u8,
    filter_method: u8,
    interlace_method: u8,
};

pub const Palette = struct {
    pub const chunk_type = "PLTE";

    entries: []struct {
        red: u8,
        green: u8,
        blue: u8,
    },
};

pub const ImageData = struct {
    pub const chunk_type = "IDAT";

    image_data: []u8,
};

pub const ImageTrailer = struct {
    pub const chunk_type = "IEND";
};

pub const acTL = struct {};
pub const cHRM = struct {};
pub const cICP = struct {};
pub const gAMA = struct {};
pub const iCCP = struct {};
pub const mDCV = struct {};
pub const cLLI = struct {};
pub const sBIT = struct {};
pub const sRGB = struct {};
pub const bKGD = struct {};
pub const hIST = struct {};
pub const tRNS = struct {};
pub const eXIf = struct {};
pub const fcTL = struct {};
pub const pHYs = struct {};
pub const sPLT = struct {};
pub const fdAT = struct {};
pub const tIME = struct {};
pub const iTXt = struct {};
pub const tEXt = struct {};
pub const zTXt = struct {};
