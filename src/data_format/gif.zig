//! GIF (GRAPHICS INTERCHANGE FORMAT)
//! https://www.w3.org/Graphics/GIF/spec-gif89a.txt

const lib = @import("../root.zig");

const number = lib.data_format.number;
const string = lib.data_format.string;
const utils = lib.data_format.utils;

pub const Header = utils.Block(.{
    .{ .signature, string.Fixed(3) },
    .{ .version, string.Fixed(3) },
});

pub const LogicalScreenDescriptor = utils.Block(.{
    .logical_screen_width = number.u16_le,
    .logical_screen_height = number.u16_le,

    .pack = utils.Pack(1, .{
        .global_color_table_flag = bool,
        .color_resolution = u3,
        .sort_flag = bool,
        .size_of_global_color_table = u3,
    }),

    .background_color_index = number.byte,
    .aspect_ratio = number.byte,
});

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

pub const DataSubBlock = utils.SizedArray(number.byte);
pub const BlockTerminator = number.Fixed(number.byte, 0x00);
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
