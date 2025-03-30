//! GIF (GRAPHICS INTERCHANGE FORMAT)
//! https://www.w3.org/Graphics/GIF/spec-gif89a.txt

const std = @import("std");
const lib = @import("../root.zig");

/// 15 - データサブブロック
pub const DataSubBlock = struct {
    /// ブロックのバイト数。
    /// ブロックサイズ自体は含まない
    block_size: u8,
    /// データ。
    /// ブロックサイズと同じ長さの必要がある。
    /// 0〜255。
    data_values: []u8,
};

/// 16 - ブロックターミネーター
pub const BlockTerminator = struct {
    /// ブロックのバイト数。
    /// ブロックサイズ自体は含まない
    /// ターミネーターのブロックサイズは0。
    block_size: u8,
};

/// 17 - ヘッダー
pub const Header = struct {
    /// 署名。
    /// GIFデータストリームの開始を表す。
    /// 値は"GIF"。
    signature: [3]u8,
    /// バージョン。
    /// 前の2文字は87から始まる数字を増加する。 ("87"〜"99", "00"〜"86")
    /// 3文字目はaから始まるアルファベットを増加する。 ("a"〜"z")
    /// - "87a"
    /// - "89a"
    version: [3]u8,
};

const number = lib.data_format.number;
const string = lib.data_format.string;
const utils = lib.data_format.utils;

const p = lib.parser.combinator;
const Result = p.Result;
const Allocator = lib.allocator.Allocator;

pub const Gif = struct {
    header: Header,
    logical_screen_descriptor: LogicalScreenDescriptor,
};

pub fn gif(allocator: Allocator, input: []const u8) Result(Gif, error{}) {
    return p.block(Gif, &.{
        .{ "header", header },
        .{ "logical_screen_descriptor", logicalScreenDescriptor },
    }).parse(allocator, input);
}

pub fn header(allocator: Allocator, input: []const u8) Result(Header, error{}) {
    return p.block(Header, &.{
        .{ "signature", p.arrayFixed(3, p.byte) },
        .{ "version", p.arrayFixed(3, p.byte) },
    }).parse(allocator, input);
}

pub const LogicalScreenDescriptor = struct {
    logical_screen_width: u16,
    logical_screen_height: u16,

    global_color_table_flag: bool,
    color_resolution: u3,
    sort_flag: bool,
    size_of_global_color_table: u3,

    background_color_index: u8,
    aspect_ratio: u8,
};
pub fn logicalScreenDescriptor(allocator: Allocator, input: []const u8) Result(LogicalScreenDescriptor, error{}) {
    return p.block(Header, &.{
        .{ "logical_screen_width", p.u16(.little) },
        .{ "logical_screen_height", p.u16(.little) },
        p.bitsSubBlock(p.byte, &.{
            .{ "global_color_table_flag", bool },
            .{ "color_resolution", u3 },
            .{ "sort_flag", bool },
            .{ "size_of_global_color_table", u3 },
        }),
        .{ "background_color_index", p.byte },
        .{ "aspect_ratio", p.byte },
    }).parse(allocator, input);
}

pub const ImageDescriptor = utils.Block(.{
    .image_separator = number.Fixed(number.byte, 0x2C),
    .image_left_position = number.u16_le,
    .image_top_position = number.u16_le,
    .image_width = number.u16_le,
    .image_height = number.u16_le,
    .pack = utils.Pack(1, .{
        .local_color_table_flag = bool,
        .interlace_flag = bool,
        .sort_flag = bool,
        .reserved = u2,
        .size_of_local_color_table = u3,
    }),
});

pub const Color = utils.Block(.{
    .red = number.byte,
    .green = number.byte,
    .blue = number.byte,
});

pub const ColorTable = utils.SizedArray(Color);

pub const SubBlocks = utils.TermArray(DataSubBlock, BlockTerminator);

pub const ImageData = utils.Block(.{
    .lzw_minimum_color_size = number.byte,
    .image_data = SubBlocks,
});

pub const GraphicControlExtention = utils.Block(.{
    .extention_introducer = number.Fixed(number.byte, 0x21),
    .graphic_control_label = number.Fixed(number.byte, 0xF9),

    .block_size = number.Fixed(number.byte, 0x04),
    .pack = utils.Pack(.{
        .reserved = u3,
        .disposal_method = enum(u3) {
            no_disposal = 0,
            do_not_disposal = 1,
            restore_to_background = 2,
            restore_to_previous = 3,
        },
        .user_input_flag = bool,
        .transparent_color_flag = bool,
    }),
    .delay_time = number.u16_le,
    .transparent_color_index = number.byte,

    .block_terminator = BlockTerminator,
});

pub const CommentExtention = utils.Block(.{
    .extention_introducer = number.Fixed(number.byte, 0x21),
    .comment_label = number.Fixed(number.byte, 0xFE),
    .comment_data = SubBlocks,
});

pub const PlainTextExtention = utils.Block(.{
    .extention_introducer = number.Fixed(number.byte, 0x21),
    .plain_text_label = number.Fixed(number.byte, 0x01),

    .block_size = number.byte,
});
