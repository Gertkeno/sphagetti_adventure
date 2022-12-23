const std = @import("std");
const w4 = @import("wasm4.zig");
const Controller = @import("Controller.zig");
const Sprite = @import("Sprite.zig");

const String = []const u8;
const Self = @This();

pub const helena_img = Sprite{
    .width = 52,
    .height = 97,
    .data = &helena_portrait,
};

readhead: ?[]const String = null,
readhead_index: usize = 0,
chardraw: u31 = 0,

talker_left: ?Sprite = helena_img,
talker_right: ?Sprite = null,

pub fn update(self: *Self, controls: Controller) bool {
    if (self.readhead == null) {
        return false;
    }
    const readhead = self.readhead.?;

    self.chardraw += 1;
    const line = readhead[self.readhead_index];
    if (line.len <= 1) {
        self.readhead = null;
        return false;
    }

    if (controls.released.x or controls.released.y) {
        const len = std.math.min(self.chardraw >> 2, line.len);
        if (len == line.len) {
            self.chardraw = 0;

            self.readhead_index += 1;
            if (self.readhead_index >= readhead.len) {
                self.readhead = null;
                return false;
            }
        } else {
            self.chardraw = @intCast(u31, line.len << 2);
        }
    }

    return true;
}

pub fn draw(self: Self) void {
    if (self.talker_left) |talker| {
        talker.draw_bl(0, 148);
    }
    if (self.talker_right) |talker| {
        talker.draw_br(160, 148);
    }
    const line = self.readhead.?[self.readhead_index];
    const len = std.math.min(self.chardraw >> 2, line.len);

    const lines = len / 19 + 1;
    const lines_height = lines * 10 + 2;

    // text border
    w4.DRAW_COLORS.* = 0x31;
    w4.rect(0, 160 - lines_height, 160, lines_height);

    // letters
    w4.DRAW_COLORS.* = 0x12;

    const y = 160 - lines_height + 2;
    var i: u31 = 0;
    while (i < lines) {
        defer i += 1;

        const start = i * 19;
        const end = std.math.min(i * 19 + 19, len);

        w4.text(line[start..end], 4, y + i * 10);
    }
}

const helena_portrait = [1261]u8{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x55, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5a, 0xaa, 0xa9, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xaa, 0xaa, 0xaa, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0xaa, 0xaa, 0xaa, 0x90, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0xa5, 0x55, 0x5a, 0x90, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1a, 0x9f, 0xdf, 0xf6, 0xa4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x7d, 0x7f, 0x7d, 0xa9, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0xa5, 0xfd, 0x57, 0xdf, 0x69, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x19, 0xa5, 0xf7, 0xfd, 0x57, 0x59, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x19, 0xa5, 0xf7, 0xff, 0xf5, 0xd6, 0x59, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x69, 0xa9, 0xdf, 0xff, 0xf5, 0xd6, 0x9a, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x69, 0x95, 0xdf, 0xff, 0xf5, 0xd6, 0xa6, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x69, 0x95, 0xd5, 0xfd, 0x75, 0x56, 0xa6, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x19, 0x69, 0x7f, 0xff, 0xf5, 0x56, 0x9a, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1a, 0x67, 0x57, 0xff, 0x55, 0x5a, 0x99, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1a, 0x57, 0x5d, 0xfd, 0xdd, 0x55, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x55, 0xdd, 0xdd, 0xdd, 0x77, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xd5, 0x77, 0xdf, 0x7d, 0xd7, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xd5, 0x7f, 0xdf, 0xfd, 0xd7, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xd5, 0x7d, 0xdf, 0xf7, 0x57, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x7d, 0xff, 0xf7, 0x75, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0xdf, 0x57, 0xf7, 0x75, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5d, 0x5f, 0xff, 0xd7, 0x75, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5d, 0x55, 0xfd, 0x57, 0xd7, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5f, 0x55, 0x55, 0x57, 0xd5, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5f, 0x55, 0xfd, 0x57, 0xdd, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5f, 0x55, 0xff, 0x55, 0xdd, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5f, 0x55, 0xfd, 0xd5, 0xdd, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5f, 0x77, 0x57, 0xdd, 0x5d, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x5f, 0x77, 0xff, 0x5d, 0xd7, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x7f, 0x7d, 0x55, 0xfd, 0xdf, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x7f, 0x7f, 0xff, 0xfd, 0xdf, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x7f, 0x7f, 0xff, 0xfd, 0xdf, 0x7d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xff, 0x77, 0x7f, 0xff, 0xfd, 0xdd, 0x7f, 0x50, 0x00, 0x00, 0x00, 0x00, 0x07, 0xff, 0x75, 0x7f, 0xff, 0xfd, 0xdd, 0x7f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x01, 0x5f, 0x75, 0x7d, 0xbf, 0x6d, 0xdd, 0x7f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x75, 0x7d, 0xbf, 0x6d, 0xdd, 0x7d, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x75, 0x7d, 0xbf, 0x6d, 0xdd, 0x7d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x75, 0x7d, 0xbf, 0x6d, 0xdd, 0x7d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5f, 0x5d, 0x7d, 0xaa, 0x6f, 0x5d, 0x7f, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x5d, 0x7d, 0x95, 0x6f, 0xdd, 0x7d, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7d, 0x5d, 0x7d, 0xbf, 0x6f, 0xdd, 0x55, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7d, 0x55, 0x7d, 0xbf, 0x6f, 0xdd, 0x5f, 0x50, 0x00, 0x00, 0x00, 0x00, 0x01, 0xfd, 0x01, 0x7d, 0x7f, 0x5f, 0xdd, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x01, 0xfd, 0x01, 0x7f, 0xff, 0xff, 0xdc, 0x07, 0xf4, 0x00, 0x00, 0x00, 0x00, 0x01, 0xf4, 0x01, 0xff, 0xff, 0xff, 0xd0, 0x07, 0xf4, 0x00, 0x00, 0x00, 0x00, 0x01, 0xf4, 0x01, 0xff, 0xff, 0xff, 0xd0, 0x01, 0xfd, 0x00, 0x00, 0x00, 0x00, 0x07, 0xf4, 0x01, 0xff, 0xff, 0xff, 0xd0, 0x01, 0xfd, 0x00, 0x00, 0x00, 0x00, 0x07, 0xd0, 0x01, 0xff, 0xff, 0xff, 0xd0, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00, 0x17, 0xd0, 0x01, 0xff, 0xff, 0xff, 0xd0, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00, 0x15, 0x50, 0x01, 0xff, 0xff, 0xff, 0xd0, 0x00, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x15, 0x40, 0x05, 0x57, 0xff, 0xff, 0xd0, 0x00, 0x1f, 0xf4, 0x00, 0x00, 0x00, 0x75, 0x40, 0x05, 0x55, 0x55, 0x55, 0x50, 0x00, 0x1f, 0xf5, 0x00, 0x00, 0x55, 0xff, 0x40, 0x05, 0x55, 0x55, 0x55, 0x50, 0x00, 0x7f, 0xfd, 0x40, 0x05, 0xd7, 0xff, 0x40, 0x05, 0x55, 0x55, 0x55, 0x50, 0x00, 0x7d, 0xfd, 0x50, 0x1d, 0x5f, 0xff, 0x40, 0x07, 0xff, 0x55, 0x55, 0x54, 0x00, 0x7d, 0x7f, 0x50, 0x05, 0xff, 0xdf, 0x40, 0x07, 0xff, 0xff, 0x55, 0x54, 0x00, 0x74, 0x77, 0x74, 0x01, 0xfd, 0x57, 0x40, 0x07, 0xff, 0xf7, 0xff, 0xd4, 0x00, 0x10, 0x77, 0x74, 0x01, 0x54, 0x07, 0x40, 0x07, 0xd7, 0xf7, 0xff, 0x74, 0x00, 0x00, 0x57, 0x54, 0x00, 0x00, 0x01, 0x00, 0x07, 0xd7, 0xf7, 0xdf, 0x74, 0x00, 0x00, 0x17, 0x40, 0x00, 0x00, 0x00, 0x00, 0x07, 0xd7, 0xf7, 0xdf, 0x74, 0x00, 0x00, 0x05, 0x40, 0x00, 0x00, 0x00, 0x00, 0x07, 0xd7, 0xf7, 0xdf, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x57, 0xf5, 0x5f, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x55, 0xf5, 0x5f, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x5d, 0x54, 0x15, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x54, 0x15, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x50, 0x15, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0xd0, 0x1f, 0xd0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x50, 0x00, 0x57, 0xd0, 0x1d, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5a, 0x95, 0x55, 0xaa, 0x50, 0x15, 0x95, 0x55, 0x55, 0x50, 0x00, 0x00, 0x01, 0xaa, 0xa5, 0xa5, 0xaa, 0x90, 0x1a, 0xaa, 0x56, 0x96, 0xa4, 0x00, 0x00, 0x06, 0xaa, 0xa5, 0xa5, 0xaa, 0x90, 0x1a, 0xaa, 0x56, 0x96, 0xa9, 0x00, 0x00, 0x06, 0xaa, 0xa5, 0xa5, 0xaa, 0x90, 0x1a, 0xaa, 0x96, 0x96, 0xa9, 0x00, 0x00, 0x06, 0xaa, 0xa5, 0xa5, 0xaa, 0x50, 0x1a, 0xaa, 0xaa, 0xaa, 0xa9, 0x00, 0x00, 0x05, 0xaa, 0xaa, 0xaa, 0xa5, 0xd0, 0x16, 0xaa, 0xaa, 0xaa, 0xa9, 0x00, 0x00, 0x05, 0x55, 0xaa, 0xaa, 0x57, 0xd0, 0x1d, 0x55, 0x5a, 0xaa, 0x95, 0x00, 0x00, 0x07, 0xff, 0x55, 0x55, 0xff, 0x40, 0x1f, 0xff, 0xd5, 0x55, 0x7d, 0x00, 0x00, 0x01, 0x5f, 0xff, 0xff, 0x55, 0x00, 0x07, 0xff, 0xff, 0xff, 0xf4, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x40, 0x00, 0x01, 0x7f, 0xff, 0xfd, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x55, 0x55, 0x00, 0x00 };
