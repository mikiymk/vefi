//! GIF (GRAPHICS INTERCHANGE FORMAT)
//! https://www.w3.org/Graphics/GIF/spec-gif89a.txt

pub const Header = utils.Block(.{
    .signature = string.Fixed("GIF"),
    .version = string.Enums(.{
        .{ "87a", .version_87a },
        .{ "89a", .version_89a },
    }),
});

pub const LogicalScreenDescriptor = utils.Block(.{
    .logical_screen_width = number.U16le,
    .logical_screen_height = number.U16le,

    .pack = utils.Pack(1, .{
         .global_color_table_flag = bool,
         .color_resolution = u3,
         .sort_flag = bool,
         .size_of_global_color_table = u3,
    }),

    .background_color_index = number.U8,
    .aspect_ratio = number.U8,
});

pub const ImageDescriptor = utils.Block(.{
    .image_separator = number.Fixed(number.U8, 0x2C),
    .image_left_position = number.U16le,
    .image_top_position = number.U16le,
    .image_width = number.U16le,
    .image_height = number.U16le,
    .pack = utils.Pack(1, .{
        .local_color_table_flag = bool,
        .interlace_flag = bool,
        .sort_flag = bool,
        .reserved = u2,
        .size_of_local_color_table = u3,
    }),
});

pub const Color = utils.Block(.{
    .red = number.U8,
    .green = number.U8,
    .blue = number.U8,
});

pub const ColorTable = utils.SizedArray(Color);

pub const DataSubBlock = utils.SizedArray(number.U8);
pub const BlockTerminator = number.Fixed(number.U8, 0x00);
pub const SubBlocks = utils.TermArray(DataSubBlock, BlockTerminator);

pub const ImageData = utils.Block(.{
    .lzw_minimum_color_size = number.U8,
    .image_data = SubBlocks,
});

pub const GraphicControlExtention = utils.Block(.{
    .extention_introducer = number.Fixed(number.U8, 0x21),
    .graphic_control_label = number.Fixed(number.U8, 0xF9),

    .block_size = number.Fixed(number.U8, 0x04),
    .pack = utils.Pack(.{
        .reserved = u3,
        .disposal_method = enum(u3) {
            .no_disposal = 0,
            .do_not_disposal = 1,
            .restore_to_background = 2,
            .restore_to_previous = 3,
        },
        .user_input_flag = bool,
        .transparent_color_flag = bool,
    }),
    .delay_time = number.U16le,
    .transparent_color_index = number.U8,

    .block_terminator = BlockTerminator,
});

pub const CommentExtention = utils.Block(.{
    .extention_introducer = number.Fixed(number.U8, 0x21),
    .comment_label = number.Fixed(number.U8, 0xFE),
    .comment_data = SubBlocks,
});

pub const PlainTextExtention = utils.Block(.{
    .extention_introducer = number.Fixed(number.U8, 0x21),
    .plain_text_label = number.Fixed(number.U8, 0x01),

    .block_size = number.U8,
});
