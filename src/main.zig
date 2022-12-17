const w4 = @import("wasm4.zig");
const std = @import("std");

const Maze = @import("Maze.zig");
const Player = @import("Player.zig");
const Controller = @import("Controller.zig");
const Quest = @import("Quest.zig");

var kiki = Quest.init_comptime(@embedFile("quest/kiki.txt"));

var gamepad: Controller = .{};
var player: Player = .{};
var rng = std.rand.DefaultPrng.init(0);

const palette = [4]u32{
    0xFFebe5ce,
    0xFFff4589,
    0xFFa64777,
    0xFF3e2653,
};

export fn start() void {
    std.mem.copy(u32, w4.PALETTE, &palette);
    w4.SYSTEM_FLAGS.* = w4.SYSTEM_PRESERVE_FRAMEBUFFER;
}

export fn update() void {
    var maze = Maze{
        .data = undefined,
    };

    w4.DRAW_COLORS.* = 0x02;
    w4.text("spagetthi meter", 0, 0);

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
        maze.generate_maze(rng.random(), .{
            .x = 0,
            .y = 0,
            .w = 160,
            .h = 160,
        });
    }

    player.update(gamepad);

    player.draw();
}
