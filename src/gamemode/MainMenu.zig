const w4 = @import("../wasm4.zig");
const std = @import("std");

const Labyrinth = @import("Labyrinth.zig");
const Controller = @import("../Controller.zig");

showing_help: bool = false,
seed: i32 = 0x849,
seed_text_buffer: [8]u8 = "849     ".*,
seed_text_len: usize = 4,

pub fn update(self: *@This(), gamepad: Controller) bool {
    if (!self.showing_help) {
        const x = gamepad.x_axis();
        if (x != 0) {
            self.seed +%= x;
            self.seed_text_len = std.fmt.formatIntBuf(&self.seed_text_buffer, @bitCast(u32, self.seed), 16, .upper, .{});
        } else if (gamepad.released.x) {
            Labyrinth.maze.generate(@bitCast(u32, self.seed));
            return true;
        } else if (gamepad.released.y) {
            // help!
            self.showing_help = true;
        }

        if (!self.showing_help) {
            w4.text("\x80  Play!", 18, 100);
            w4.text("\x84\x85 Seed", 18, 110);
            w4.text("\x81  Help!", 18, 130);
            w4.text(self.seed_text_buffer[0..self.seed_text_len], 20 + 8 * 8, 110);
        }
    } else {
        w4.text("pickup keys!", 0, 0);

        if (gamepad.released.x or gamepad.released.y) {
            self.showing_help = false;
        }
    }

    return false;
}
