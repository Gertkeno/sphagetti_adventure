const w4 = @import("wasm4.zig");
const std = @import("std");

const GameMode = @import("gamemode/Gamemode.zig").GameModes;
const Controller = @import("Controller.zig");

// start at the main menu via game mode switching, futher defined in src/gamemode/Gamemode.zig
var gamemode = GameMode{
    .main_menu = .{},
};

var gamepad = Controller{};

// we use this color palette from lospec: https://lospec.com/palette-list/heart4
const palette = [4]u32{
    0xFFebe5ce,
    0xFFff4589,
    0xFFa64777,
    0xFF3e2653,
};

export fn start() void {
    // set the color palette once
    std.mem.copy(u32, w4.PALETTE, &palette);
}

export fn update() void {
    // we only use the first player gamepad
    gamepad.update(w4.GAMEPAD1.*);

    gamemode.update(gamepad);
}
