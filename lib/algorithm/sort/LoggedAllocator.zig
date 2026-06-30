//! アロケーション回数などを記録する。

const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = std.log.debug;

const lib = @import("../../root.zig");

test {
    std.testing.refAllDecls(@This());
}

child_allocator: Allocator,
/// メモリ確保を要求した回数
alloc_count: usize = 0,
/// 現在のメモリ空間サイズ。 max_allocatedを求めるために使用する。
current_allocated: usize = 0,
/// 最大メモリ空間サイズ。
max_allocated: usize = 0,

pub fn init(child_allocator: Allocator) @This() {
    return .{ .child_allocator = child_allocator };
}

/// カウントをリセットする。
pub fn resetCount(self: *@This()) void {
    self.alloc_count = 0;
    self.current_allocated = 0;
    self.max_allocated = 0;
}

/// アロケーターを作成する。
pub fn allocator(self: *@This()) Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, n: usize, alignment: std.mem.Alignment, ra: usize) ?[*]u8 {
    const self: *@This() = @ptrCast(@alignCast(ctx));
    const result = self.child_allocator.vtable.alloc(self.child_allocator.ptr, n, alignment, ra);
    if (result != null) {
        self.alloc_count += 1;
        self.current_allocated += n;
        self.max_allocated = @max(self.current_allocated, self.max_allocated);
    }
    return result;
}

fn resize(ctx: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ra: usize) bool {
    const self: *@This() = @ptrCast(@alignCast(ctx));
    const success = self.child_allocator.vtable.resize(self.child_allocator.ptr, buf, alignment, new_len, ra);
    if (success) {
        self.alloc_count += 1;
        self.current_allocated -= buf.len;
        self.current_allocated += new_len;
        self.max_allocated = @max(self.current_allocated, self.max_allocated);
    }
    return success;
}

fn remap(ctx: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ra: usize) ?[*]u8 {
    const self: *@This() = @ptrCast(@alignCast(ctx));
    const result = self.child_allocator.vtable.remap(self.child_allocator.ptr, buf, alignment, new_len, ra);
    if (result != null) {
        self.alloc_count += 1;
        self.current_allocated -= buf.len;
        self.current_allocated += new_len;
        self.max_allocated = @max(self.current_allocated, self.max_allocated);
    }
    return result;
}

fn free(ctx: *anyopaque, buf: []u8, alignment: std.mem.Alignment, ra: usize) void {
    const self: *@This() = @ptrCast(@alignCast(ctx));
    self.current_allocated -= buf.len;
    self.child_allocator.vtable.free(self.child_allocator.ptr, buf, alignment, ra);
}
