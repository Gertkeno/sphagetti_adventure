const w4 = @import("../wasm4.zig");
const std = @import("std");

const Labyrinth = @import("Labyrinth.zig");
const Controller = @import("../Controller.zig");

seleting_new_game: bool = true,
seed: i32 = 2121,
seed_text_buffer: [8]u8 = "849     ".*,
seed_text_len: usize = 4,

pub fn update(self: *@This(), gamepad: Controller) bool {
    if (gamepad.released.up or gamepad.released.down) {
        self.seleting_new_game = !self.seleting_new_game;
    }

    if (!self.seleting_new_game) {
        self.seed +%= gamepad.x_axis();
        self.seed_text_len = std.fmt.formatIntBuf(&self.seed_text_buffer, @bitCast(u32, self.seed), 16, .upper, .{});
    } else {
        if (gamepad.released.x or gamepad.released.y) {
            Labyrinth.maze.generate(@bitCast(u32, self.seed));
            return true;
        }
    }

    w4.text(">>", 2, if (self.seleting_new_game) 100 else 110);
    w4.text("Play!", 18, 100);
    w4.text("Set seed:", 18, 110);
    w4.text(self.seed_text_buffer[0..self.seed_text_len], 20 + 9 * 8, 110);

    return false;
}
