const w4 = @import("wasm4.zig");

const Maze = @import("Maze.zig");
const Point = @import("Point.zig");
const Rect = @import("Rect.zig");
const Self = @This();

const width = 8;
const height = 5;
const roach_img = [10]u8{ 0x55, 0x55, 0x07, 0x6d, 0x57, 0x69, 0x05, 0x55, 0x01, 0x11 };

pos: Point,
dir: Point,

pub fn update(self: *Self, maze: Maze) void {
    self.pos = self.pos.add(self.dir);

    if (!maze.walkable(self.to_rect())) {
        self.pos = self.pos.sub(self.dir);
        self.dir = self.dir.scale(-1);
    }
}

pub fn to_rect(self: Self) Rect {
    return Rect{
        .x = self.pos.x,
        .y = self.pos.y,
        .w = width,
        .h = height,
    };
}

pub fn draw(self: Self, camera: Point) void {
    const view = self.pos.sub(camera);
    const flip = if (self.dir.x > 0 or self.dir.y > 0) w4.BLIT_FLIP_X else 0;

    w4.blit(&roach_img, view.x, view.y, width, height, flip | w4.BLIT_2BPP);
}
