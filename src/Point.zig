const Self = @This();
x: i32,
y: i32,

pub fn scale(self: Self, scalar: i32) Self {
    return Self{
        .x = self.x * scalar,
        .y = self.y * scalar,
    };
}

pub fn shrink(self: Self, scalar: i32) Self {
    return Self{
        .x = @divTrunc(self.x, scalar),
        .y = @divTrunc(self.y, scalar),
    };
}

pub const zero = Self{ .x = 0, .y = 0 };
pub const one = Self{ .x = 1, .y = 1 };
