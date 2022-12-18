const w4 = @import("wasm4.zig");
const std = @import("std");
const Point = @import("Point.zig");
const Rect = @import("Rect.zig");
const Self = @This();

pub const Tile = enum(u8) {
    empty,
    wall,
    breakable,
    door,
};

data: []Tile,

const maze_width = 160;
const maze_height = 90;
const tile_size = 8;

fn hline(self: Self, x: i32, y: i32, w: u31) void {
    const start = @intCast(usize, x + y * maze_width);
    for (self.data[start .. start + w]) |*data| {
        data.* = .wall;
    }
}

fn vline(self: Self, x: i32, y: i32, w: u31) void {
    var iy = y;
    while (iy < y + w) : (iy += 1) {
        const i = @intCast(usize, x + iy * maze_width);
        self.data[i] = .wall;
    }
}

const room_scale = 2;
fn generate_maze(self: Self, rng: std.rand.Random, area: Rect) void {
    if (area.w < room_scale * 3 or area.h < room_scale * 3) {
        return;
    }
    const w = rng.intRangeLessThanBiased(u31, room_scale, area.w - room_scale);
    const h = rng.intRangeLessThanBiased(u31, room_scale, area.h - room_scale);

    const gaps = [4]u31{
        rng.uintLessThanBiased(u31, h),
        rng.intRangeLessThanBiased(u31, h + 1, area.h),

        rng.uintLessThanBiased(u31, w),
        rng.intRangeLessThanBiased(u31, w + 1, area.w),
    };

    const bisects = [4]Rect{
        Rect{
            .x = area.x,
            .y = area.y,
            .w = w,
            .h = h,
        },
        Rect{
            .x = area.x + w,
            .y = area.y,
            .w = @intCast(u31, area.w - w),
            .h = h,
        },
        Rect{
            .x = area.x,
            .y = area.y + h,
            .w = w,
            .h = @intCast(u31, area.h - h),
        },
        Rect{
            .x = area.x + w,
            .y = area.y + h,
            .w = @intCast(u31, area.w - w),
            .h = @intCast(u31, area.h - h),
        },
    };

    self.hline(area.x, area.y + h, area.w);
    self.vline(area.x + w, area.y, area.h);

    for (gaps) |gap, n| {
        const x = area.x + if (n < 2) w else gap;
        const y = area.y + if (n < 2) gap else h;

        const ipixel: usize = @intCast(usize, y * maze_width + x);
        self.data[ipixel] = .empty;
    }

    for (bisects) |bisect| {
        self.generate_maze(rng, bisect);
    }
}

pub fn generate(self: Self, seed: u32) void {
    std.mem.set(Tile, self.data, .empty);
    var rng = std.rand.DefaultPrng.init(seed);
    self.generate_maze(rng.random(), .{
        .x = 0,
        .y = 0,
        .w = maze_width,
        .h = maze_height,
    });
}

const test_tile = [tile_size]u8{
    0b11000011,
    0b10000001,
    0b00100100,
    0b00100100,
    0b00000000,
    0b00100100,
    0b10011001,
    0b11000011,
};

// we have pretty weird coordinates. need to reduce camera position into maze
// cells with an offset. could use x & 0b1111 depending on the tile size if a
// factor of 2
pub fn draw(self: Self, camera: Point) void {
    const reduced_wh = w4.SCREEN_SIZE / tile_size;

    const inset_x = @mod(camera.x, tile_size);
    const mx = @divTrunc(camera.x, tile_size);
    const maxx = std.math.min(mx + reduced_wh + 1, maze_width);

    var my = @divTrunc(camera.y, tile_size);
    const maxy = std.math.min(my + reduced_wh + 1, maze_height);
    while (my < maxy) : (my += 1) {
        const start = @intCast(usize, mx + my * maze_width);
        const end = @intCast(usize, maxx + my * maze_width);

        for (self.data[start..end]) |tile, n| {
            if (tile == .wall) {
                const x = @intCast(i32, n) * tile_size - inset_x;
                const y = my * tile_size - camera.y;
                w4.blit(&test_tile, x, y, tile_size, tile_size, w4.BLIT_1BPP);
            }
        }
    }
}
