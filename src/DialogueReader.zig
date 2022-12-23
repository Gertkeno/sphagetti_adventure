const std = @import("std");
const w4 = @import("wasm4.zig");
const Controller = @import("Controller.zig");

const String = []const u8;

const Self = @This();

readhead: ?[]const String = null,
readhead_index: usize = 0,
chardraw: usize = 0,

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
            self.chardraw = line.len << 2;
        }
    }

    return true;
}

pub fn draw(self: Self) void {
    // text border
    w4.DRAW_COLORS.* = 0x31;
    w4.rect(0, 138, 160, 160 - 138);

    // letters
    w4.DRAW_COLORS.* = 0x12;
    const line = self.readhead.?[self.readhead_index];
    const len = std.math.min(self.chardraw >> 2, line.len);

    if (len > 19) {
        w4.text(line[0..19], 4, 140);
        w4.text(line[19..len], 4, 150);
    } else {
        w4.text(line[0..len], 4, 150);
    }
}
