const std = @import("std");

const String = []const u8;
const Self = @This();

const Sequence = union(enum) {
    new_slide: [*]const u8,
    text: String,
};

items: []Sequence,

fn char_count(dialogue: String) usize {
    var count: usize = 0;
    var lineitr = std.mem.tokenize(u8, dialogue, ";");
    while (lineitr.next()) |line| {
        if (line[0] != '!') {
            const trimmed = std.mem.trim(u8, line, &std.ascii.spaces);

            count += trimmed.len;
        }
    }
    return count;
}

pub fn init_comptime(comptime dialogue: String, imgs: anytype) Self {
    @setEvalBranchQuota(99999);
    const token_count = std.mem.count(u8, dialogue, ";");

    var sequences: [token_count + 1]Sequence = undefined;
    var seq_index: usize = 0;

    const tc = char_count(dialogue);
    var text_buffer: [tc]u8 = undefined;
    var text_index: usize = 0;

    var tokenItr = std.mem.tokenize(u8, dialogue, ";");
    while (tokenItr.next()) |t| {
        const token = std.mem.trim(u8, t, &std.ascii.spaces);
        if (token[0] == '!') {
            sequences[seq_index] = Sequence{
                .new_slide = @field(imgs, token[1..]),
            };
            seq_index += 1;
        } else {
            std.mem.copy(u8, text_buffer[text_index..], token);
            const new_text = text_buffer[text_index .. text_index + token.len];

            sequences[seq_index] = Sequence{
                .text = new_text,
            };
            seq_index += 1;

            text_index += token.len;
        }
    }

    return Self{
        .items = &sequences,
    };
}
