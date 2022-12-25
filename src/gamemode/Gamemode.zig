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
    pub fn update(self: *Self, controller: Controller) void {
        switch (meta.activeTag(self.*)) {
            .labyrinth => {
                if (@ptrCast(*Labyrinth, self).update(controller)) {
                    self.* = GameModes{ .cutscene = Cutscene{ .from = .labyrinth } };
                }
            },
            .main_menu => {
                if (@ptrCast(*MainMenu, self).update(controller)) {
                    self.* = GameModes{ .cutscene = Cutscene{ .from = .main_menu } };
                }
            },
            .boss_fight => {
                if (@ptrCast(*BossFight, self).update(controller)) {
                    self.* = GameModes{ .cutscene = Cutscene{ .from = .boss_fight } };
                }
            },
            .cutscene => {
                const ptr = @ptrCast(*Cutscene, self);
                if (ptr.update(controller)) {
                    self.* = switch (ptr.from) {
                        .main_menu => GameModes{ .labyrinth = Labyrinth{} },
                        //.main_menu => GameModes{ .boss_fight = BossFight{} },
                        .labyrinth => GameModes{ .boss_fight = BossFight{} },
                        .boss_fight => GameModes{ .main_menu = MainMenu{} },
                    };
                }
            },
        }
    }
};

comptime {
    const too_big = 100;
    if (@sizeOf(GameModes) > too_big) {
        for (meta.fields(GameModes)) |field| {
            if (@sizeOf(field.field_type) > too_big) {
                @compileError(field.name ++ " too big!");
            }
        }
    }
}
