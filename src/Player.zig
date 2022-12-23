const w4 = @import("wasm4.zig");
const std = @import("std");

const Maze = @import("Maze.zig");
const Point = @import("Point.zig");
const Rect = @import("Rect.zig");
const Controller = @import("Controller.zig");

extern var maze: Maze;

const Self = @This();

const attack_frames: u8 = 8;

const width = 8;
const height = 8;

pos: Point = Point{
    .x = 25 * 16 + 80,
    .y = 25 * 16 + 80,
},

health: i32 = 160,
attacking: u8 = 0,

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
    const offset = self.pos.add(self.facing.scale(15));
    return Rect{
        .x = offset.x,
        .y = offset.y,
        .w = 14,
        .h = 14,
    };
}

pub fn update(self: *Self, controller: Controller) void {
    const x = controller.x_axis();
    const y = controller.y_axis();

    self.pos.x += x;
    if (!maze.walkable(self.to_rect())) {
        self.pos.x -= if (x == 0) @as(i4, 5) else x;
    }
    self.pos.y += y;
    if (!maze.walkable(self.to_rect())) {
        self.pos.y -= if (y == 0) @as(i4, 5) else y;
    }

    if (x != 0 or y != 0) {
        self.facing = Point{ .x = x, .y = y };
    }

    if (controller.released.x) {
        self.attacking = attack_frames;
        // apply hitbox
    } else if (self.attacking > 0) {
        self.attacking -= 1;
    }
}

fn circle(pos: Point, r: u31) void {
    const r2 = r * 2;
    w4.oval(pos.x - r, pos.y - r, r2, r2);
}

pub fn draw(self: Self, camera: Point) void {
    const view = self.pos.sub(camera);
    if (self.attacking > 0) {
        w4.DRAW_COLORS.* = 0x44;

        const midpoint = view.add(Point{ .x = width / 2, .y = height / 2 });

        const crecent = midpoint.add(self.facing.scale(8));
        const negative = midpoint.add(self.facing.scale(6));
        circle(crecent, 7);
        w4.DRAW_COLORS.* = 0x21;
        circle(negative, 5);
    }

    w4.DRAW_COLORS.* = 0x12;
    w4.blit(&smiley, view.x, view.y, width, height, w4.BLIT_1BPP);
}

const smiley = [height]u8{
    0b11000011,
    0b10000001,
    0b00100100,
    0b00100100,
    0b00000000,
    0b00100100,
    0b10011001,
    0b11000011,
};

pub fn collide_point(self: Self, x: i32, y: i32) bool {
    return (x > self.x) and (x < self.x + width) and (y > self.y) and (y < self.y + height);
}
