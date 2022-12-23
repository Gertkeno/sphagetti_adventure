const w4 = @import("../wasm4.zig");
const std = @import("std");

const Maze = @import("../Maze.zig");
const Player = @import("../Player.zig");
const Quest = @import("../Quest.zig");

const Sprite = @import("../Sprite.zig");
const Controller = @import("../Controller.zig");
const Reader = @import("../DialogueReader.zig");
const Point = @import("../Point.zig");
const Roach = @import("../Roach.zig");

player: Player = .{},
camera: Point = Point.zero,
reader: Reader = .{},
active_roaches: usize = roach_data.len,
respawn_time: u16 = 0,

const roach_respawn_time = 25 * 60;
var kiki = Quest.init_comptime(@embedFile("../quest/kiki.txt"), kiki_img);
const kiki_img = Sprite{
    .width = 52,
    .height = 48,
    .data = &kiki_portrait,
};
const kiki_portrait = [624]u8{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x00, 0x01, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x00, 0x01, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x00, 0x05, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x40, 0x05, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x54, 0x00, 0x01, 0x55, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x54, 0x00, 0x05, 0x55, 0x54, 0x00, 0x00, 0x00, 0x00, 0x01, 0x55, 0x55, 0x55, 0x55, 0x00, 0x15, 0x55, 0x55, 0x00, 0x00, 0x00, 0x15, 0x01, 0x56, 0xd5, 0x5b, 0x55, 0x00, 0x15, 0x55, 0x55, 0x40, 0x00, 0x00, 0x00, 0x55, 0x56, 0x95, 0x5a, 0x55, 0x15, 0x15, 0x00, 0x55, 0x50, 0x00, 0x00, 0x00, 0x05, 0x55, 0x55, 0x55, 0x55, 0x40, 0x55, 0x00, 0x15, 0x50, 0x00, 0x00, 0x00, 0x05, 0x55, 0x55, 0x55, 0x54, 0x00, 0x55, 0x00, 0x05, 0x54, 0x00, 0x00, 0x00, 0x15, 0x55, 0x59, 0x55, 0x54, 0x00, 0x54, 0x15, 0x05, 0x54, 0x00, 0x00, 0x05, 0x41, 0x56, 0x59, 0x65, 0x50, 0x00, 0x55, 0x15, 0x01, 0x54, 0x00, 0x00, 0x14, 0x00, 0x55, 0xa6, 0x95, 0x55, 0x40, 0x55, 0x15, 0x01, 0x54, 0x00, 0x00, 0x00, 0x01, 0x55, 0x55, 0x55, 0x40, 0x50, 0x15, 0x55, 0x01, 0x54, 0x00, 0x00, 0x00, 0x05, 0x55, 0x55, 0x55, 0x00, 0x04, 0x15, 0x55, 0x00, 0x55, 0x00, 0x00, 0x00, 0x15, 0x55, 0x55, 0x55, 0x00, 0x00, 0x05, 0x54, 0x00, 0x55, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x00, 0x00, 0x01, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x00, 0x00, 0x15, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x00, 0x05, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x01, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x01, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x05, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x15, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x15, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x15, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x15, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x15, 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x15, 0x45, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x55, 0x54, 0x15, 0x45, 0x40, 0x00, 0x00, 0x00, 0x00, 0x15, 0x55, 0x55, 0x55, 0x55, 0x54, 0x15, 0x45, 0x40, 0x00, 0x00, 0x00, 0x00, 0x15, 0x55, 0x55, 0x55, 0x55, 0x50, 0x15, 0x45, 0x40, 0x00, 0x00, 0x00, 0x00, 0x15, 0x55, 0x55, 0x55, 0x55, 0x40, 0x05, 0x51, 0x50, 0x00, 0x00, 0x00, 0x00, 0x05, 0x55, 0x55, 0x55, 0x55, 0x55, 0x51, 0x51, 0x54, 0x00, 0x00, 0x00, 0x00, 0x05, 0x55, 0x55, 0x55, 0x55, 0x55, 0x51, 0x54, 0x55, 0x00, 0x00, 0x00, 0x00, 0x01, 0x55, 0x55, 0x55, 0x55, 0x55, 0x51, 0x54, 0x55, 0x00 };

var roach_data: [50]Roach = undefined;
var maze_data: [Maze.array_size]Maze.Tile = undefined;
pub var maze = Maze{
    .tiles = &maze_data,
    .roaches = &roach_data,
};

pub fn update(self: *@This(), gamepad: Controller) void {
    const draw_text = self.reader.update(gamepad);
    if (!draw_text) {
        if (gamepad.released.y) {
            self.reader = kiki.talk(0);
        }

        self.player.update(gamepad, &maze);

        self.camera = self.player.pos.sub(Point.one.scale(80));

        self.camera.x = std.math.clamp(self.camera.x, 0, Maze.view_max_x);
        self.camera.y = std.math.clamp(self.camera.y, 0, Maze.view_max_y);

        for (roach_data[0..self.active_roaches]) |*roach| {
            roach.update(maze);
        }
        if (self.player.attacking > 0) {
            const hitbox = self.player.hitbox();
            for (roach_data[0..self.active_roaches]) |roach, n| {
                if (roach.to_rect().collides(hitbox)) {
                    self.active_roaches -= 1;
                    std.mem.swap(Roach, &roach_data[self.active_roaches], &roach_data[n]);
                    break;
                }
            }
        } else if (self.player.invincible == 0) {
            const player = self.player.to_rect();
            for (roach_data[0..self.active_roaches]) |roach| {
                if (roach.to_rect().collides(player)) {
                    self.player.take_damage(1);
                    break;
                }
            }
        }

        self.respawn_time += 1;

        if (self.respawn_time > roach_respawn_time) {
            if (self.active_roaches < roach_data.len) {
                self.active_roaches += 1;
            }
            self.respawn_time = 0;
        }
    }

    maze.draw(self.camera);

    w4.DRAW_COLORS.* = 0x1230;
    for (roach_data[0..self.active_roaches]) |roach| {
        roach.draw(self.camera);
    }

    self.player.draw(self.camera);

    if (draw_text) {
        self.reader.draw();
    }
}
