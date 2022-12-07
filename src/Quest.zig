const w4 = @import("wasm4.zig");
const std = @import("std");

const String = []const u8;
const Controller = @import("Controller.zig");

const Self = @This();

const Dialogue = struct {
    progress: u8,
    lines: []String,
};

// read head
progress: u8 = 0,
readhead: ?[]const String = null,
readhead_index: usize = 0,
chardraw: usize = 0,

// data
dialogue: []Dialogue,

fn dialog_descending(_: void, lhs: Dialogue, rhs: Dialogue) bool {
    return lhs.progress > rhs.progress;
}

fn line_count(dialogue: String) usize {
    var count: usize = 0;
    var lineitr = std.mem.tokenize(u8, dialogue, "\n");
    while (lineitr.next()) |line| {
        if (line[0] != '#') {
            count += 1;
        }
    }

    return count;
}

fn char_count(dialogue: String) usize {
    var count: usize = 0;
    var lineitr = std.mem.tokenize(u8, dialogue, "\n");
    while (lineitr.next()) |line| {
        if (line[0] != '#') {
            const trimmed = std.mem.trim(u8, line, &std.ascii.spaces);

            count += trimmed.len;
        }
    }
    return count;
}

pub fn init_comptime(comptime dialogue: String) Self {
    @setEvalBranchQuota(9999);
    const page_count = std.mem.count(u8, dialogue, "#");

    if (page_count == 0) {
        @compileError("dialogue must have at least one page");
    }

    var pages: [page_count]Dialogue = undefined;
    var page_index: usize = 0;
    var line_index: usize = 0;

    const lc = line_count(dialogue);
    var lines_buffer: [lc]String = undefined;
    var buffer_index: usize = 0;

    const tc = char_count(dialogue);
    var text_buffer: [tc]u8 = undefined;
    var text_index: usize = 0;

    var tokenItr = std.mem.tokenize(u8, dialogue, "#\n");
    while (tokenItr.next()) |t| {
        const token = std.mem.trim(u8, t, &std.ascii.spaces);
        if (std.fmt.parseUnsigned(u8, token, 10)) |progress| {
            pages[page_index].progress = progress;
            if (page_index > 0) {
                const start = buffer_index - line_index;
                const end = buffer_index;
                pages[page_index - 1].lines = lines_buffer[start..end];
            }
            page_index += 1;
            line_index = 0;
        } else |_| {
            std.mem.copy(u8, text_buffer[text_index..], token);
            const new_text = text_buffer[text_index .. text_index + token.len];

            lines_buffer[buffer_index] = new_text;

            text_index += token.len;
            line_index += 1;
            buffer_index += 1;
        }
    }

    if (page_index > 0) {
        const start = buffer_index - line_index;
        const end = buffer_index;
        pages[page_index - 1].lines = lines_buffer[start..end];
    }

    const sort = std.sort.sort;
    sort(Dialogue, &pages, {}, dialog_descending);

    return Self{
        .dialogue = &pages,
    };
}

pub fn talk(self: *Self, update_progress: ?u8) void {
    self.progress = update_progress orelse self.progress;

    const head = for (self.dialogue) |dialog| {
        if (dialog.progress <= self.progress) {
            break dialog.lines;
        }
    } else {
        return;
    };

    self.readhead = head;
    self.readhead_index = 0;
    self.chardraw = 0;
}

pub fn update_draw(self: *Self, controls: Controller) bool {
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

    const len = std.math.min(self.chardraw >> 2, line.len);
    if (controls.released.x or controls.released.y) {
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

    if (len > 19) {
        w4.text(line[0..19], 4, 140);
        w4.text(line[19..len], 4, 150);
    } else {
        w4.text(line[0..len], 4, 150);
    }

    return true;
}
