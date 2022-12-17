const w4 = @import("wasm4.zig");
const std = @import("std");
const Rect = @import("Rect.zig");
const Self = @This();

data: []bool,

pub fn initialize(data: []bool) Self {
    if (data.len < 160 * 160) {
        w4.trace("initialized maze needs more memory!");
    }

    return Self{
        .data = data,
    };
}

const density = 4;
pub fn generate_maze(self: Self, rng: std.rand.Random, area: Rect) void {
    if (area.w < density * 3 or area.h < density * 3) {
        return;
    }
    const w = rng.uintLessThanBiased(u31, area.w - density * 2) + density;
    const h = rng.uintLessThanBiased(u31, area.h - density * 2) + density;

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

    for (bisects) |bisect| {
        self.generate_maze(rng, bisect);
    }
}
