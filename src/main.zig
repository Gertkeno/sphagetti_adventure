const w4 = @import("wasm4.zig");
const std = @import("std");

const Player = @import("Player.zig");
const Controller = @import("Controller.zig");
const Quest = @import("Quest.zig");

var kiki = Quest.init_comptime(@embedFile("quest/kiki.txt"));

var gamepad: Controller = .{};
var player: Player = .{};

const palette = [4]u32{
    0xFFebe5ce,
    0xFFff4589,
    0xFFa64777,
    0xFF3e2653,
};

export fn start() void {
    std.mem.copy(u32, w4.PALETTE, &palette);
}

export fn update() void {
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
    }

    player.update(gamepad);

    player.draw();
}
