const meta = @import("std").meta;
const Controller = @import("../Controller.zig");

// game modes
const Labyrinth = @import("Labyrinth.zig");
const MainMenu = @import("MainMenu.zig");
const BossFight = @import("BossFight.zig");
const Cutscene = @import("Cutscene.zig");

pub const GameModes = union(enum) {
    labyrinth: Labyrinth,
    main_menu: MainMenu,
    cutscene: Cutscene,
    boss_fight: BossFight,

    const Self = @This();

    // if any game mode's update returns true we know to switch to the cutscene when complete will
    // update the game mode to a new state, from main_menu to labyrinth to boss_fight
    pub fn update(self: *Self, controller: Controller) void {
        switch (meta.activeTag(self.*)) {
            .labyrinth => {
                if (@as(*Labyrinth, @ptrCast(self)).update(controller)) {
                    self.* = GameModes{ .cutscene = Cutscene{ .from = .labyrinth } };
                }
            },
            .main_menu => {
                if (@as(*MainMenu, @ptrCast(self)).update(controller)) {
                    self.* = GameModes{ .cutscene = Cutscene{ .from = .main_menu } };
                }
            },
            .boss_fight => {
                if (@as(*BossFight, @ptrCast(self)).update(controller)) {
                    self.* = GameModes{ .cutscene = Cutscene{ .from = .boss_fight } };
                }
            },
            .cutscene => {
                const ptr: *Cutscene = @as(*Cutscene, @ptrCast(self));
                if (ptr.update(controller)) {
                    self.* = switch (ptr.from) {
                        .main_menu => GameModes{ .labyrinth = Labyrinth{} },
                        .labyrinth => GameModes{ .boss_fight = BossFight{} },
                        .boss_fight => GameModes{ .main_menu = MainMenu{} },
                    };
                }
            },
        }
    }
};
