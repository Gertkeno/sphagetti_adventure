const Gamepad = packed struct {
    x: bool = false,
    y: bool = false,
    _: u2 = 0,
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,
};

const Self = @This();

previous: u8 = 0,

pressed: Gamepad = .{},
held: Gamepad = .{},
released: Gamepad = .{},

pub fn update(self: *Self, newgamepad: u8) void {
    self.previous = @bitCast(u8, self.held);
    self.held = @bitCast(Gamepad, newgamepad);

    self.pressed = @bitCast(Gamepad, newgamepad & newgamepad ^ self.previous);
    self.released = @bitCast(Gamepad, self.previous & newgamepad ^ self.previous);
}

fn axis(self: Self, comptime low: []const u8, comptime high: []const u8) i2 {
    var o: i2 = 0;

    if (@field(self.held, low))
        o -= 1;
    if (@field(self.held, high))
        o += 1;

    return o;
}

pub fn x_axis(self: Self) i2 {
    return self.axis("left", "right");
}

pub fn y_axis(self: Self) i2 {
    return self.axis("up", "down");
}
