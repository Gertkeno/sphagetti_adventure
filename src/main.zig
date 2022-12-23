const w4 = @import("wasm4.zig");
const std = @import("std");

const Labyrinth = @import("gamemode/Labyrinth.zig");
const GameMode = @import("gamemode/Gamemode.zig").GameModes;
const Controller = @import("Controller.zig");

var gamemode = GameMode{
    .labyrinth = .{},
};

var gamepad = Controller{};

const palette = [4]u32{
    0xFFebe5ce,
    0xFFff4589,
    0xFFa64777,
    0xFF3e2653,
};

export fn start() void {
    std.mem.copy(u32, w4.PALETTE, &palette);
    //w4.SYSTEM_FLAGS.* = w4.SYSTEM_PRESERVE_FRAMEBUFFER;
    Labyrinth.maze.generate(2121);
}

export fn update() void {
    gamepad.update(w4.GAMEPAD1.*);

    gamemode.update(gamepad);
}
