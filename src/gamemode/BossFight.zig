const w4 = @import("../wasm4.zig");
const std = @import("std");

const Point = @import("../Point.zig");
const Rect = @import("../Rect.zig");
const Controller = @import("../Controller.zig");
const Player = @import("../Player.zig");

const Self = @This();

boss: Rect = .{
    .x = 70,
    .y = 0,
    .w = 20,
    .h = 20,
},
player: Player = .{
    .pos = .{ .x = 76, .y = 68 },
},

pub fn update(self: *Self, controller: Controller) bool {
    self.player.update(controller, null);

    self.player.draw(Point.zero);

    self.player.pos.x = std.math.clamp(self.player.pos.x, 0, 152);
    self.player.pos.y = std.math.clamp(self.player.pos.y, 0, 148);

    return false;
}
