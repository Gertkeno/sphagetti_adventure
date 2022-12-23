const w4 = @import("wasm4.zig");
const std = @import("std");

const Point = @import("Point.zig");
const Rect = @import("Rect.zig");
const Self = @This();

const Roach = @import("Roach.zig");

pub const Tile = enum(u8) {
    empty,
    wall,
    breakable,
    crumbled,
    door,
};

data: []Tile,

const maze_width = 70;
const maze_height = 70;
pub const array_size = maze_width * maze_height;

const tile_size = 16;
pub const view_max_x = maze_width * tile_size - w4.SCREEN_SIZE;
pub const view_max_y = maze_height * tile_size - w4.SCREEN_SIZE;

const door_chance = 3;

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

const room_scale = 3;
fn generateMaze(self: Self, rng: std.rand.Random, area: Rect) void {
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
        self.generateMaze(rng, bisect);
    }
}

const NeighborSet = std.StaticBitSet(4);

fn findNeighbors(self: Self, index: usize, of_type: Tile) NeighborSet {
    var output = NeighborSet.initEmpty();

    // north
    if (index > maze_width) {
        const n = self.data[index - maze_width];
        output.setValue(0, n == of_type);
    }
    // east
    if (index % maze_width != maze_width - 1) {
        const e = self.data[index + 1];
        output.setValue(1, e == of_type);
    }
    // south
    if (index < maze_width * (maze_height - 1)) {
        const s = self.data[index + maze_width];
        output.setValue(2, s == of_type);
    }
    // west
    if (index % maze_width > 0) {
        const w = self.data[index - 1];
        output.setValue(3, w == of_type);
    }

    return output;
}

fn makeBreakable(data: *Tile) void {
    if (data.* == .wall) {
        data.* = .breakable;
    }
}

fn breakableNeighbors(self: Self, index: usize) void {
    self.data[index] = .breakable;

    if (index % maze_width > 0) {
        makeBreakable(&self.data[index - 1]);
    }
    if (index % maze_width != maze_width - 1) {
        makeBreakable(&self.data[index + 1]);
    }

    if (index > maze_width) {
        makeBreakable(&self.data[index - maze_width]);
    }
    if (index < maze_width * (maze_height - 1)) {
        makeBreakable(&self.data[index + maze_width]);
    }
}

pub fn generate(self: Self, seed: u32) void {
    std.mem.set(Tile, self.data, .empty);
    var rng = std.rand.DefaultPrng.init(seed);
    self.generateMaze(rng.random(), .{
        .x = 0,
        .y = 0,
        .w = maze_width,
        .h = maze_height,
    });

    for (self.data) |*data, n| {
        if (data.* == .empty) {
            const neighbors = self.findNeighbors(n, .wall);

            if ((neighbors.mask == 0b1010 or neighbors.mask == 0b0101) and n % door_chance == 0) {
                data.* = .door;
            } else if (neighbors.count() >= 3) {
                self.breakableNeighbors(n);
            }
        }
    }
}

pub fn draw(self: Self, camera: Point) void {
    w4.DRAW_COLORS.* = 0x13;
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
            if (tile == .empty)
                continue;

            const x = @intCast(i32, n) * tile_size - inset_x;
            const y = my * tile_size - camera.y;
            const art: [*]const u8 = switch (tile) {
                .wall => &wall_br,
                .door => &door,
                .breakable => &breakable,
                .crumbled => &crumbled,
                .empty => unreachable,
            };

            w4.blit(art, x, y, tile_size, tile_size, w4.BLIT_1BPP);
        }
    }
}

pub fn hit_breakable(self: *Self, area: Rect) void {
    const midpoint = area.midpoint().shrink(tile_size);

    const index = midpoint.x + midpoint.y * maze_width;
    if (index > 0 and index < array_size) {
        const i = @intCast(usize, index);
        if (self.data[i] == .breakable) {
            self.data[i] = .crumbled;
        }
    }
}

pub fn walkable(self: Self, area: Rect) bool {
    if (area.x < 0 or area.y < 0) {
        return false;
    } else if (area.x + area.w >= maze_width * tile_size) {
        return false;
    } else if (area.y + area.h >= maze_height * tile_size) {
        return false;
    }

    const vertecies = [4]i32{
        @divTrunc(area.x, tile_size) + @divTrunc(area.y, tile_size) * maze_width,
        @divTrunc(area.x + area.w, tile_size) + @divTrunc(area.y, tile_size) * maze_width,
        @divTrunc(area.x, tile_size) + @divTrunc(area.y + area.h, tile_size) * maze_width,
        @divTrunc(area.x + area.w, tile_size) + @divTrunc(area.y + area.h, tile_size) * maze_width,
    };

    for (vertecies) |vertex| {
        const tile = self.data[@intCast(u32, vertex)];

        if (tile != .empty and tile != .crumbled) {
            return false;
        }
    }

    return true;
}

const wall_br = [32]u8{ 0x80, 0x00, 0x5f, 0xfe, 0x3f, 0xfe, 0x6f, 0xfc, 0x7f, 0xfe, 0x7f, 0xfc, 0x7f, 0xfc, 0x7f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfc, 0x7f, 0xf8, 0x5f, 0xe4, 0x2a, 0xd0, 0x00, 0x01 };
const door = [32]u8{ 0xe0, 0x07, 0xdf, 0xfb, 0xbf, 0xfd, 0xbf, 0xfd, 0x7f, 0xfe, 0x7f, 0xfe, 0x1f, 0xfe, 0x7f, 0xf6, 0x7f, 0xea, 0x7f, 0xea, 0x7f, 0xf6, 0x1f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfe, 0x00, 0x00 };
const breakable = [32]u8{ 0xe2, 0x67, 0xd8, 0x8b, 0xdc, 0x5d, 0xbe, 0xbd, 0xbe, 0xbe, 0xbf, 0x7c, 0x7f, 0x7e, 0x7e, 0xfc, 0x7e, 0xfc, 0xfe, 0xfe, 0x7f, 0x7e, 0xff, 0xfe, 0x7e, 0xfe, 0x7f, 0x7c, 0x9f, 0xfa, 0xe0, 0x01 };
const crumbled = [32]u8{ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0x9f, 0xfb, 0xef, 0xff, 0xaf, 0xfd, 0xdf, 0xff, 0xff, 0xfd, 0xff, 0xfa, 0xdf, 0xfb, 0xbf, 0xfc, 0xff, 0xff, 0xff, 0xff, 0xff };
