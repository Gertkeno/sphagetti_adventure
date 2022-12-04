const w4 = @import("wasm4.zig");
const std = @import("std");

const String = []const u8;
const Controller = @import("Controller.zig");

const Self = @This();

progress: u8 = 0,
chardraw: usize = 0,
readhead: ?usize = null,
dialogue: String,

fn find_head(file: String, progress: u8) ?usize {
    var buffer: [3]u8 = undefined;
    const strlen = std.fmt.formatIntBuf(&buffer, progress, 10, .lower, .{});

    const str = buffer[0..strlen];

    if (std.mem.indexOf(u8, file, str)) |index| {
        if (std.mem.indexOfScalar(u8, file[index..], '\n')) |end| {
            return index + end + 1;
        } else {
            return null;
        }
    } else {
        return null;
    }
}

fn get_line(string: String) String {
    if (std.mem.indexOfScalar(u8, string, '\n')) |end| {
        return std.mem.trimLeft(u8, string[0..end], &std.ascii.spaces);
    } else {
        return std.mem.trim(u8, string, &std.ascii.spaces);
    }
}

pub fn talk(self: *Self, update_progress: ?u8) void {
    self.progress = update_progress orelse self.progress;

    self.readhead = find_head(self.dialogue, self.progress);
}

pub fn update_draw(self: *Self, controls: Controller) bool {
    if (self.readhead == null) {
        return false;
    }

    self.chardraw += 1;
    const line = get_line(self.dialogue[self.readhead.?..]);
    if (line.len <= 1) {
        self.readhead = null;
        return false;
    }

    const len = std.math.min(self.chardraw >> 2, line.len);
    if (controls.released.x or controls.released.y) {
        if (len == line.len) {
            self.chardraw = 0;

            self.readhead.? += line.len + 1;
            if (self.readhead.? >= self.dialogue.len or self.dialogue[self.readhead.?] == '0') {
                self.readhead = null;
                return false;
            }
        } else {
            self.chardraw = line.len << 2;
        }
    }

    if (len > 19) {
        w4.text(line[0..19], 4, 140);
        w4.text(line[19..len], 4, 150);
    } else {
        w4.text(line[0..len], 4, 150);
    }

    return true;
}
