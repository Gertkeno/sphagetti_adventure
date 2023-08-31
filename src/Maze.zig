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
    torch_lit,
    torch_unlit,
    door,
    door_open,
};

tiles: []Tile,
roaches: []Roach,

const maze_width = 70;
const maze_height = 70;
pub const array_size = maze_width * maze_height;

const tile_size = 16;
pub const view_max_x: i32 = maze_width * tile_size - w4.SCREEN_SIZE;
pub const view_max_y: i32 = maze_height * tile_size - w4.SCREEN_SIZE;

const door_chance = 3;

// write a line of walls horizontally
fn hline(self: Self, x: i32, y: i32, w: u16) void {
    const start: usize = @intCast(x + y * maze_width);
    for (self.tiles[start .. start + w]) |*tile| {
        tile.* = .wall;
    }
}

// write a line of walls vertically
fn vline(self: Self, x: i32, y: i32, w: u16) void {
    var iy = y;
    while (iy < y + w) : (iy += 1) {
        const i: usize = @intCast(x + iy * maze_width);
        self.tiles[i] = .wall;
    }
}

// room_scale is the approximate minimum number of tiles for a square room. At 2 hallways can form
// that fill with door, but 3 is plenty dense.
const room_scale = 3;
fn generateMaze(self: Self, rng: std.rand.Random, area: Rect) void {
    if (area.w < room_scale * 3 or area.h < room_scale * 3) {
        return;
    }
    const w = rng.intRangeLessThanBiased(u16, room_scale, area.w - room_scale);
    const h = rng.intRangeLessThanBiased(u16, room_scale, area.h - room_scale);

    const quadrants = [4]Rect{
        Rect{
            .x = area.x,
            .y = area.y,
            .w = w,
            .h = h,
        },
        Rect{
            .x = area.x + w,
            .y = area.y,
            .w = @intCast(area.w - w),
            .h = h,
        },
        Rect{
            .x = area.x,
            .y = area.y + h,
            .w = w,
            .h = @intCast(area.h - h),
        },
        Rect{
            .x = area.x + w,
            .y = area.y + h,
            .w = @intCast(area.w - w),
            .h = @intCast(area.h - h),
        },
    };

    self.hline(area.x, area.y + h, area.w);
    self.vline(area.x + w, area.y, area.h);

    const gaps = [4]u16{
        rng.uintLessThanBiased(u16, h),
        rng.intRangeLessThanBiased(u16, h + 1, area.h),

        rng.uintLessThanBiased(u16, w),
        rng.intRangeLessThanBiased(u16, w + 1, area.w),
    };

    // Remove walls to create random gaps. These gaps may turn into doors or breakable rocks.
    // There must be at least 1 hole in every quadrant to make the maze solvable.
    for (gaps, 0..) |gap, n| {
        const x = area.x + if (n < 2) w else gap;
        const y = area.y + if (n < 2) gap else h;

        const ipixel: usize = @intCast(y * maze_width + x);
        self.tiles[ipixel] = .empty;
    }

    for (quadrants) |quadrant| {
        self.generateMaze(rng, quadrant);
    }

    // the first quadrants created will be far apart, we separate the flames by quadrant so the
    // player may search for a fairly long time.
    const first = area.x == 0 and area.w == maze_width;
    if (first) {
        // four quadrants but only three flames, we must skip generating in one of them.
        const skip = rng.uintLessThanBiased(u3, 4);
        for (quadrants, 0..) |quadrant, n| {
            if (n == skip)
                continue;
            const midpoint = quadrant.midpoint();
            const midpoint_index: usize = @intCast(midpoint.x + midpoint.y * maze_width);
            self.tiles[midpoint_index] = .torch_lit;
        }
    }
}

const NeighborSet = std.StaticBitSet(4);

fn findNeighbors(self: Self, index: usize, of_type: Tile) NeighborSet {
    var output = NeighborSet.initEmpty();

    // north
    if (index > maze_width) {
        const n = self.tiles[index - maze_width];
        output.setValue(0, n == of_type);
    }
    // east
    if (index % maze_width != maze_width - 1) {
        const e = self.tiles[index + 1];
        output.setValue(1, e == of_type);
    }
    // south
    if (index < maze_width * (maze_height - 1)) {
        const s = self.tiles[index + maze_width];
        output.setValue(2, s == of_type);
    }
    // west
    if (index % maze_width > 0) {
        const w = self.tiles[index - 1];
        output.setValue(3, w == of_type);
    }

    return output;
}

fn makeBreakable(tile: *Tile) void {
    if (tile.* == .wall) {
        tile.* = .breakable;
    }
}

fn breakableNeighbors(self: Self, index: usize) void {
    self.tiles[index] = .breakable;

    if (index % maze_width > 0) {
        makeBreakable(&self.tiles[index - 1]);
    }
    if (index % maze_width != maze_width - 1) {
        makeBreakable(&self.tiles[index + 1]);
    }

    if (index > maze_width) {
        makeBreakable(&self.tiles[index - maze_width]);
    }
    if (index < maze_width * (maze_height - 1)) {
        makeBreakable(&self.tiles[index + maze_width]);
    }
}

pub fn generate(self: Self, seed: u32) void {
    @memset(self.tiles, .empty);
    var rng = std.rand.DefaultPrng.init(seed);
    const random = rng.random();

    self.generateMaze(random, .{
        .x = 0,
        .y = 0,
        .w = maze_width,
        .h = maze_height,
    });

    for (self.tiles, 0..) |*tile, n| {
        if (tile.* == .empty) {
            const neighbors = self.findNeighbors(n, .wall);

            if ((neighbors.mask == 0b1010 or neighbors.mask == 0b0101) and n % door_chance == 0) {
                // if a empty tile has two walls on either side we probably made that gap so the
                // player may pass, but every now and then we want a door to block them for a while.
                tile.* = .door;
            } else if (neighbors.count() >= 3) {
                // if a empty tile has three or more walls around it, it means we made a gap that is
                // supposed to be traversable, but it will filled around by later quadrant
                // generations. To fix this we turn the crossroads into breakable rocks.
                self.breakableNeighbors(n);
            }
        }
    }

    // pick random empty tiles to spawn lil roaches.
    var nextIndex: usize = 0;
    while (nextIndex < self.roaches.len) {
        const tileIndex = random.uintLessThanBiased(usize, self.tiles.len);

        if (self.tiles[tileIndex] == .empty) {
            const x = @as(i32, @intCast(tileIndex % maze_width)) * 16 + 3;
            const y = @as(i32, @intCast(tileIndex / maze_width)) * 16 + 5;
            // roaches should only move up/down or left/right, NOT diagonally.
            const dirtest = random.boolean();
            self.roaches[nextIndex] = Roach{
                .pos = .{ .x = x, .y = y },
                .dir = .{ .x = if (dirtest) 1 else 0, .y = if (dirtest) 0 else 1 },
            };
            nextIndex += 1;
        }
    }
}

pub fn draw(self: Self, camera: Point) void {
    w4.DRAW_COLORS.* = 0x13;
    const reduced_wh = w4.SCREEN_SIZE / tile_size;

    const inset_x = @mod(camera.x, tile_size);
    const mx = @divTrunc(camera.x, tile_size);
    const maxx = @min(mx + reduced_wh + 1, maze_width);

    var my = @divTrunc(camera.y, tile_size);
    const maxy = @min(my + reduced_wh + 1, maze_height);
    while (my < maxy) : (my += 1) {
        const start: usize = @intCast(mx + my * maze_width);
        const end: usize = @intCast(maxx + my * maze_width);

        for (self.tiles[start..end], 0..) |tile, n| {
            if (tile == .empty)
                continue;

            const x = @as(i32, @intCast(n)) * tile_size - inset_x;
            const y = my * tile_size - camera.y;
            const art: [*]const u8 = switch (tile) {
                .wall => &wall_br,
                .door => &door,
                .door_open => &door_open,
                .breakable => &breakable,
                .crumbled => &crumbled,
                .torch_lit => &brazier_lit,
                .torch_unlit => &brazier_unlit,
                .empty => unreachable,
            };

            w4.DRAW_COLORS.* = if (tile == .torch_lit) 0x12 else 0x13;

            w4.blit(art, x, y, tile_size, tile_size, w4.BLIT_1BPP);
        }
    }
}

// if hit by area convert a tile
fn hit_to(self: *Self, area: Rect, from: Tile, to: Tile) bool {
    const midpoint = area.midpoint().shrink(tile_size);

    const index = midpoint.x + midpoint.y * maze_width;
    if (index > 0 and index < self.tiles.len) {
        const i: usize = @intCast(index);
        if (self.tiles[i] == from) {
            self.tiles[i] = to;
            return true;
        }
    }

    return false;
}

pub fn hit_breakable(self: *Self, area: Rect) bool {
    return self.hit_to(area, .breakable, .crumbled);
}

pub fn hit_torch(self: *Self, area: Rect) bool {
    return self.hit_to(area, .torch_lit, .torch_unlit);
}

pub fn hit_door(self: *Self, area: Rect) bool {
    return self.hit_to(area, .door, .door_open);
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
        const tile = self.tiles[@intCast(vertex)];

        switch (tile) {
            .empty, .crumbled, .torch_lit, .torch_unlit, .door_open => {},
            // ^ walkable tiles ^

            .wall, .door, .breakable => {
                // ^ unwalkable tiles ^
                return false;
            },
        }
    }

    return true;
}

const wall_br = [32]u8{ 0x80, 0x00, 0x5f, 0xfe, 0x3f, 0xfe, 0x6f, 0xfc, 0x7f, 0xfe, 0x7f, 0xfc, 0x7f, 0xfc, 0x7f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfc, 0x7f, 0xf8, 0x5f, 0xe4, 0x2a, 0xd0, 0x00, 0x01 };
const door = [32]u8{ 0xe0, 0x07, 0xdf, 0xfb, 0xbf, 0xfd, 0xbf, 0xfd, 0x7f, 0xfe, 0x7f, 0xfe, 0x1f, 0xfe, 0x7f, 0xf6, 0x7f, 0xea, 0x7f, 0xea, 0x7f, 0xf6, 0x1f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfe, 0x7f, 0xfe, 0x00, 0x00 };
const breakable = [32]u8{ 0xe2, 0x67, 0xd8, 0x8b, 0xdc, 0x5d, 0xbe, 0xbd, 0xbe, 0xbe, 0xbf, 0x7c, 0x7f, 0x7e, 0x7e, 0xfc, 0x7e, 0xfc, 0xfe, 0xfe, 0x7f, 0x7e, 0xff, 0xfe, 0x7e, 0xfe, 0x7f, 0x7c, 0x9f, 0xfa, 0xe0, 0x01 };
const crumbled = [32]u8{ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0x9f, 0xfb, 0xef, 0xff, 0xaf, 0xfd, 0xdf, 0xff, 0xff, 0xfd, 0xff, 0xfa, 0xdf, 0xfb, 0xbf, 0xfc, 0xff, 0xff, 0xff, 0xff, 0xff };
const brazier_unlit = [32]u8{ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xdf, 0xfb, 0xc1, 0x83, 0xe0, 0x07, 0xf8, 0x1f, 0xfe, 0x7f, 0xff, 0xff, 0xff, 0xff };
const brazier_lit = [32]u8{ 0xff, 0x7f, 0xfe, 0x7f, 0xf8, 0x7f, 0xf9, 0xff, 0xf3, 0x1f, 0xf2, 0x0f, 0xf2, 0x4f, 0xf3, 0xcf, 0xf8, 0x1f, 0xdc, 0x7b, 0xc1, 0x83, 0xe0, 0x07, 0xf8, 0x1f, 0xfe, 0x7f, 0xff, 0xff, 0xff, 0xff };
const door_open = [32]u8{ 0xcf, 0xff, 0xcf, 0xff, 0xb7, 0xff, 0xb7, 0xff, 0x7b, 0xff, 0x7b, 0xff, 0x3b, 0xff, 0x7b, 0xff, 0x7b, 0xff, 0x7b, 0xff, 0x7b, 0xff, 0x3b, 0xff, 0x7b, 0xff, 0x7b, 0xff, 0x73, 0xff, 0x07, 0xff };
