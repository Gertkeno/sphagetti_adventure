const w4 = @import("wasm4.zig");
const std = @import("std");

const Controller = @import("Controller.zig");

const Self = @This();

const subpixel = 2;
const width = 8;
const height = 8;

x: i32 = 80 * subpixel,
y: i32 = 80 * subpixel,

health: i32 = 160,

pub fn update(self: *Self, controller: Controller) void {
    const x = controller.x_axis();
    const y = controller.y_axis();

    self.x += x;
    self.y += y;
}

pub fn draw(self: Self) void {
    const x = @divTrunc(self.x, subpixel);
    const y = @divTrunc(self.y, subpixel);
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
