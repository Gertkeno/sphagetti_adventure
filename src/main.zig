const w4 = @import("wasm4.zig");
const std = @import("std");

const Maze = @import("Maze.zig");
const Player = @import("Player.zig");
const Controller = @import("Controller.zig");
const Quest = @import("Quest.zig");
const Reader = @import("DialogueReader.zig");

const Point = @import("Point.zig");

var kiki = Quest.init_comptime(@embedFile("quest/kiki.txt"));

var gamepad = Controller{};
var player = Player{};
var camera = Point.zero;
var reader = Reader{};

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
    maze.generate(2121);
}

export fn update() void {
    gamepad.update(w4.GAMEPAD1.*);

    const draw_text = reader.update(gamepad);
    if (!draw_text) {
        if (gamepad.released.y) {
            reader = kiki.talk(0);
        }

        player.update(gamepad);

        camera = player.pos.sub(Point.one.scale(80));

        camera.x = std.math.clamp(camera.x, 0, Maze.view_max_x);
        camera.y = std.math.clamp(camera.y, 0, Maze.view_max_y);
    }

    maze.draw(camera);

    player.draw(camera);

    if (draw_text) {
        reader.draw();
    }
}
