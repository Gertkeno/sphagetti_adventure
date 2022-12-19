const w4 = @import("wasm4.zig");
const std = @import("std");

const Maze = @import("Maze.zig");
const Player = @import("Player.zig");
const Controller = @import("Controller.zig");
const Quest = @import("Quest.zig");

const Point = @import("Point.zig");

var kiki = Quest.init_comptime(@embedFile("quest/kiki.txt"));

var gamepad: Controller = .{};
var player: Player = .{};
var camera = Point.zero;

const palette = [4]u32{
    0xFFebe5ce,
    0xFFff4589,
    0xFFa64777,
    0xFF3e2653,
};

var maze_data: [Maze.array_size]Maze.Tile = undefined;
export var maze = Maze{
    .data = &maze_data,
};

export fn start() void {
    std.mem.copy(u32, w4.PALETTE, &palette);
    //w4.SYSTEM_FLAGS.* = w4.SYSTEM_PRESERVE_FRAMEBUFFER;
}

export fn update() void {
    w4.DRAW_COLORS.* = 0x02;

    gamepad.update(w4.GAMEPAD1.*);
    if (gamepad.held.x) {
        w4.DRAW_COLORS.* = 0x04;
    }

    if (kiki.update_draw(gamepad)) {
        return;
    }

    if (gamepad.released.y) {
        kiki.talk(0);
    } else if (gamepad.released.x) {
        maze.generate(@bitCast(u32, camera.x));
    }

    player.update(gamepad);

    camera.x = player.x - 80;
    camera.y = player.y - 80;

    camera.x = std.math.max(0, camera.x);
    camera.y = std.math.max(0, camera.y);

    maze.draw(camera);

    player.draw(camera);
}
