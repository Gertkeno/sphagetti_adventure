const std = @import("std");
const w4 = @import("wasm4.zig");
const Controller = @import("Controller.zig");

const String = []const u8;

const Self = @This();

readhead: ?[]const String = null,
readhead_index: usize = 0,
chardraw: u31 = 0,

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
