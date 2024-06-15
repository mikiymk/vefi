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
    .image_separator = number.Fixed(@as(u8, 0x2C)),
    .image_left_position = number.U16le,
    .image_top_position = number.U16le,
    .image_width = number.U16le,
    .image_height = number.U16le,
    .pack = utils.Pack(1, .{
        
    }),
});

pub const Color = utils.Block(.{
    .red = number.U8,
    .green = number.U8,
    .blue = number.U8,
});

pub const ColorTable = utils.SizedArray(Color);
