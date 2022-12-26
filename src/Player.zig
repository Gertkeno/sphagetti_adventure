const w4 = @import("wasm4.zig");
const std = @import("std");

const Maze = @import("Maze.zig");
const Point = @import("Point.zig");
const Rect = @import("Rect.zig");
const Controller = @import("Controller.zig");

const Self = @This();

const attack_power_time: u8 = 40;
const attack_frames: u8 = 8;

const width = 8;
const height = 12;

pos: Point = Point{
    .x = 25 * 16 + 84,
    .y = 25 * 16 + 83,
},

health: i16 = 160,

attack_held: u8 = 0,
attacking: u4 = 0,
power_attack: bool = false,
invincible: u8 = 0,

facing: Point = Point.up,

pub fn to_rect(self: Self) Rect {
    return Rect{
        .x = self.pos.x,
        .y = self.pos.y,
        .w = width - 1,
        .h = height - 1,
    };
}

pub fn hitbox(self: Self) Rect {
    const offset = self.pos.add(self.facing.scale(9));
    return Rect{
        .x = offset.x - 3,
        .y = offset.y - 2,
        .w = 15,
        .h = 15,
    };
}

pub fn update(self: *Self, controller: Controller, maze: ?*Maze) void {
    const x = controller.x_axis();
    const y = controller.y_axis();

    self.pos.x += x;
    if (maze != null and !maze.?.walkable(self.to_rect())) {
        self.pos.x -= if (x == 0) @as(i4, 5) else x;
    }
    self.pos.y += y;
    if (maze != null and !maze.?.walkable(self.to_rect())) {
        self.pos.y -= if (y == 0) @as(i4, 5) else y;
    }

    if (x != 0 or y != 0) {
        self.facing = Point{ .x = x, .y = y };
    }

    if (controller.held.x) {
        self.attack_held += 1;
        if (self.attack_held > 200) {
            self.attack_held = attack_power_time;
        }
    }
    if (controller.released.x or controller.released.y) {
        self.power_attack = self.attack_held >= attack_power_time;
        self.attack_held = 0;
        self.attacking = attack_frames;

        if (maze != null and self.power_attack) {
            _ = maze.?.hit_breakable(self.hitbox());
        }
        // apply hitbox
    } else if (self.attacking > 0) {
        self.attacking -= 1;
    }

    if (self.invincible > 0) {
        self.invincible -= 1;
    }
}

fn circle(pos: Point, r: u31) void {
    const r2 = r * 2;
    w4.oval(pos.x - r, pos.y - r, r2, r2);
}

pub fn draw(self: Self, camera: Point) void {
    const view = self.pos.sub(camera);
    if (self.attacking > 0) {
        w4.DRAW_COLORS.* = if (self.power_attack) 0x22 else 0x44;
        const midpoint = view.add(Point{ .x = width / 2, .y = height / 2 });

        // the attack is made with two circles one to fill in and the other to subtract, forming a
        // crecent.
        const fill = midpoint.add(self.facing.scale(8));
        const negative = midpoint.add(self.facing.scale(6));
        circle(fill, 7);
        w4.DRAW_COLORS.* = if (self.power_attack) 0x31 else 0x21;
        circle(negative, 5);
    }

    const invincible_flash = self.invincible & 0b110 == 0;
    if (invincible_flash) {
        const power_flash = self.attack_held >= attack_power_time and self.attack_held & 0b10100 == 0;
        w4.DRAW_COLORS.* = if (power_flash) 0x4120 else 0x1240;
        w4.blit(&helena_pc, view.x, view.y, width, height, w4.BLIT_2BPP);
    }
}

pub fn take_damage(self: *Self, damage: u8) void {
    self.health -= damage;
    self.invincible = 50;
}

pub fn is_alive(self: Self) bool {
    return self.health > 0;
}

// helena_pc
const helena_pc = [24]u8{ 0x0a, 0xa0, 0x19, 0x64, 0x27, 0xd8, 0x27, 0xd8, 0x55, 0x55, 0x79, 0x6d, 0xda, 0xa7, 0x49, 0x61, 0x05, 0x50, 0x15, 0x54, 0x01, 0x10, 0x01, 0x10 };
