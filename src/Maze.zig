const w4 = @import("wasm4.zig");
const std = @import("std");
const Rect = @import("Rect.zig");
const Self = @This();

pub const Tile = enum(u8) {
    empty,
    wall,
    breakable,
    door,
};

data: []Tile,

pub fn initialize(data: []Tile) Self {
    if (data.len < 160 * 160) {
        w4.trace("initialized maze needs more memory!");
    }

    return Self{
        .data = data,
    };
}

fn hline(self: Self, x: i32, y: i32, w: u31) void {
    const start = @intCast(usize, x + y * 160);
    for (self.data[start..w]) |*data| {
        data.* = .wall;
    }
}

fn vline(self: Self, x: i32, y: i32, w: u31) void {
    var iy = y;
    while (iy < y + w) : (iy += 1) {
        const i = @intCast(usize, x + iy * 160);
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

    w4.hline(area.x, area.y + h, area.w);
    w4.vline(area.x + w, area.y, area.h);

    for (gaps) |gap, n| {
        const x = area.x + if (n < 2) w else gap;
        const y = area.y + if (n < 2) gap else h;

        const ipixel: usize = @intCast(usize, y * 160 + x) / 4;
        const shift: u3 = @intCast(u3, (x & 0b11) * 2);
        const mask: u8 = @as(u8, 0b11) << shift;

        w4.FRAMEBUFFER[ipixel] = (@as(u8, 0b00) << shift) | (w4.FRAMEBUFFER[ipixel] & ~mask);
    }

    for (bisects) |bisect| {
        self.generate_maze(rng, bisect);
    }
}

pub fn generate(self: Self, seed: u32) void {
    //std.mem.set(Tile, self.data, .empty);
    var rng = std.rand.DefaultPrng.init(seed);
    self.generate_maze(rng.random(), .{
        .x = 0,
        .y = 0,
        .w = 160,
        .h = 160,
    });
}

const Camera = @import("Camera.zig");

//pub fn draw(self: Self, camera: Camera) void { }
