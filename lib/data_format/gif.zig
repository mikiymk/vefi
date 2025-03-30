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

/// 18 - 論理スクリーン記述子
pub const LogicalScreenDescriptor = struct {
    /// 論理スクリーン幅
    logical_screen_width: u16,
    /// 論理スクリーン高さ
    logical_screen_height: u16,

    /// グローバルカラーテーブルフラグ
    global_color_table_flag: u1,
    /// カラー解像度
    color_resolution: u3,
    /// カラーソートフラグ
    sort_flag: u1,
    /// グローバルカラーテーブルサイズ
    size_of_global_color_table: u3,

    /// 背景色インデックス
    background_color_index: u8,
    /// アスペクト比
    aspect_ratio: u8,
};

/// 19 - グローバルカラーテーブル
/// 21 - ローカルカラーテーブル
pub const ColorTable = struct {
    colors: []u8,
};

/// 20 - 画像記述子
pub const ImageDescriptor = struct {
    image_separator: u8,
    image_left_position: u16,
    image_top_position: u16,
    image_width: u16,
    image_height: u16,

    local_color_table_flag: u1,
    interlace_flag: u1,
    sort_flag: u1,
    reserved: u2,
    size_of_local_color_table: u3,
};

/// 22 - テーブルベースの画像データ
pub const TableBasedImageData = struct {
    lzw_minimum_code_size: u8,
    image_data: []DataSubBlock,
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
