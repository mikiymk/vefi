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

/// 23 - グラフィックコントロール拡張
pub const GraphicControlExtention = struct {
    extention_introducer: u8,
    graphic_control_label: u8,

    block_size: u8,
    reserved: u3,
    disposal_method: u3,
    user_input_flag: u1,
    transparent_color_flag: u1,
    delay_time: u8,
    transparent_color_index: u8,

    block_terminator: u8,
};

/// 24 - コメント拡張
pub const CommentExtention = struct {
    extention_introducer: u8,
    comment_label: u8,

    comment_data: []DataSubBlock,

    block_terminator: u8,
};

/// 25 - プレーンテキスト拡張
pub const PlainTextExtention = struct {
    extention_introducer: u8,
    plain_text_label: u8,

    block_size: u8,
    text_grid_left_position: u16,
    text_grid_top_position: u16,
    text_grid_width: u16,
    text_grid_height: u16,
    character_cell_width: u8,
    character_cell_height: u8,
    text_foreground_color_index: u8,
    text_background_color_index: u8,

    plain_text_data: []DataSubBlock,

    block_terminator: u8,
};

/// 26 - アプリケーション拡張
pub const ApplicationExtention = struct {
    extention_introducer: u8,
    extention_label: u8,

    block_size: u8,
    application_identifier: [8]u8,
    application_authentication_code: [3]u8,

    application_code: []DataSubBlock,

    block_terminator: u8,
};

/// 27 - トレーラー
pub const Trailer = struct {
    gif_trailer: u8,
};
