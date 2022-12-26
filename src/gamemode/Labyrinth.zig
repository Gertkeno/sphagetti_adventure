const w4 = @import("../wasm4.zig");
const std = @import("std");

const Maze = @import("../Maze.zig");
const Player = @import("../Player.zig");

const Sprite = @import("../Sprite.zig");
const Controller = @import("../Controller.zig");
const Point = @import("../Point.zig");
const Roach = @import("../Roach.zig");

const Self = @This();

player: Player = .{},
camera: Point = Point.zero,
active_roaches: u16 = roach_data.len,
respawn_time: u16 = 0,
flame_got: u2 = 0,
keys: u8 = 1 * key_pieces, // start with 1 full key
key_text: [2]u8 = "01".*,

const roach_respawn_time = 25 * 60;

var roach_data: [50]Roach = undefined;
var maze_data: [Maze.array_size]Maze.Tile = undefined;
pub var maze = Maze{
    .tiles = &maze_data,
    .roaches = &roach_data,
};

const key_pieces = 4;
fn total_keys(self: Self) u8 {
    return self.keys / key_pieces;
}

fn update_key_counter(self: *Self) void {
    _ = std.fmt.formatIntBuf(&self.key_text, self.total_keys(), 10, .lower, .{
        .width = 2,
        .fill = '0',
    });
}

pub fn update(self: *Self, gamepad: Controller) bool {
    self.player.update(gamepad, &maze);
    if (maze.hit_torch(self.player.to_rect())) {
        self.flame_got += 1;
    }

    self.camera = self.player.pos.sub(Point.one.scale(w4.SCREEN_SIZE / 2));

    // the camera cannot move out of bounds
    self.camera.x = std.math.clamp(self.camera.x, 0, Maze.view_max_x);
    self.camera.y = std.math.clamp(self.camera.y, 0, Maze.view_max_y);

    for (roach_data[0..self.active_roaches]) |*roach| {
        roach.update(maze);
    }

    if (self.player.attacking > 0) {
        const hitbox = self.player.hitbox();
        for (roach_data[0..self.active_roaches]) |roach, n| {
            if (roach.to_rect().collides(hitbox)) {
                if (self.keys < 255) {
                    self.keys += 1;
                    self.update_key_counter();
                }
                self.active_roaches -= 1;
                std.mem.swap(Roach, &roach_data[self.active_roaches], &roach_data[n]);
                break;
            }
        }

        if (self.total_keys() > 0 and maze.hit_door(hitbox)) {
            self.keys -= key_pieces;
            self.update_key_counter();
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

    // respawn lil roaches
    self.respawn_time += 1;
    if (self.respawn_time > roach_respawn_time) {
        if (self.active_roaches < roach_data.len) {
            // revive the roach that died first
            std.mem.swap(Roach, &roach_data[roach_data.len - 1], &roach_data[self.active_roaches]);
            self.active_roaches += 1;
        }
        self.respawn_time = 0;
    }

    maze.draw(self.camera);

    w4.DRAW_COLORS.* = 0x1230;
    for (roach_data[0..self.active_roaches]) |roach| {
        roach.draw(self.camera);
    }

    self.player.draw(self.camera);

    // hud
    {
        const x = 160 - 8 * 2 - 4;
        const w = 160 - x;
        w4.DRAW_COLORS.* = 0x31;
        w4.rect(x - 2, 141, w + 3, 20);

        // key fill
        w4.DRAW_COLORS.* = 0x03;
        w4.blit(&key, x, 152, key_width, key_height, w4.BLIT_ROTATE | w4.BLIT_FLIP_X);

        w4.DRAW_COLORS.* = 0x04;
        const key_segment = (self.keys % key_pieces) * 2;
        w4.blitSub(&key, x, 152, key_segment, key_height, 0, 0, 8, w4.BLIT_ROTATE | w4.BLIT_FLIP_X);

        // key count
        w4.text(&self.key_text, x + 4, 152);

        // flames count
        var ti: u2 = 0;
        while (ti < 3) : (ti += 1) {
            w4.DRAW_COLORS.* = if (self.flame_got > ti) 0x12 else 0x13;
            const tx = @intCast(i32, ti) * 7 + x;
            w4.blit(&flame_collect, tx, 143, flame_collect_width, flame_collect_height, flame_collect_flags);
        }
    }

    return self.flame_got == 3;
}

// key
const key_width = 8;
const key_height = 3;
const key_flags = 0; // BLIT_1BPP
const key = [3]u8{ 0x9d, 0x40, 0x3a };

// flame_collect
const flame_collect_width = 8;
const flame_collect_height = 6;
const flame_collect_flags = w4.BLIT_ROTATE; // BLIT_1BPP
const flame_collect = [6]u8{ 0xc7, 0xb9, 0x2c, 0x77, 0x8f, 0xdf };
