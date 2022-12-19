const w4 = @import("wasm4.zig");
const std = @import("std");

const Maze = @import("Maze.zig");
const Point = @import("Point.zig");
const Rect = @import("Rect.zig");
const Controller = @import("Controller.zig");

extern var maze: Maze;

const Self = @This();

const width = 8;
const height = 8;

x: i32 = 25 * 16 + 80,
y: i32 = 25 * 16 + 80,

health: i32 = 160,

pub fn to_rect(self: Self) Rect {
    return Rect{
        .x = self.x,
        .y = self.y,
        .w = width - 1,
        .h = height - 1,
    };
}

pub fn update(self: *Self, controller: Controller) void {
    const x = controller.x_axis();
    const y = controller.y_axis();

    self.x += x;
    if (!maze.walkable(self.to_rect())) {
        self.x -= if (x == 0) @as(i4, 5) else x;
    }
    self.y += y;
    if (!maze.walkable(self.to_rect())) {
        self.y -= if (y == 0) @as(i4, 5) else y;
    }
}

pub fn draw(self: Self, camera: Point) void {
    const x = self.x - camera.x;
    const y = self.y - camera.y;
    w4.blit(&smiley, x, y, width, height, w4.BLIT_1BPP);
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
