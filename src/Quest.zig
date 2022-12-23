const w4 = @import("wasm4.zig");
const std = @import("std");

const String = []const u8;
const Self = @This();

const Dialogue = struct {
    progress: u8,
    lines: []String,
};

progress: u8 = 0,
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

const Reader = @import("DialogueReader.zig");
pub fn talk(self: *Self, update_progress: ?u8) Reader {
    self.progress = update_progress orelse self.progress;

    const head = for (self.dialogue) |dialog| {
        if (dialog.progress <= self.progress) {
            break dialog.lines;
        }
    } else {
        unreachable;
    };

    return Reader{
        .readhead = head,
        .readhead_index = 0,
        .chardraw = 0,
    };
}
