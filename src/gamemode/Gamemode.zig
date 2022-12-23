const meta = @import("std").meta;
const Controller = @import("../Controller.zig");

// game modes
const Labyrinth = @import("Labyrinth.zig");
const MainMenu = @import("MainMenu.zig");

pub const GameModes = union(enum) {
    labyrinth: Labyrinth,
    main_menu: MainMenu,

    const Self = @This();
    pub fn update(self: *Self, controller: Controller) void {
        switch (meta.activeTag(self.*)) {
            .labyrinth => @ptrCast(*Labyrinth, self).update(controller),
            .main_menu => {
                if (@ptrCast(*MainMenu, self).update(controller)) {
                    self.* = GameModes{ .labyrinth = Labyrinth{} };
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
