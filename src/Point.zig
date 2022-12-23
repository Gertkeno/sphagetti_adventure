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

pub fn add(a: Self, b: Self) Self {
    return Self{
        .x = a.x + b.x,
        .y = a.y + b.y,
    };
}

pub fn sub(a: Self, b: Self) Self {
    return Self{
        .x = a.x - b.x,
        .y = a.y - b.y,
    };
}

pub const zero = Self{ .x = 0, .y = 0 };
pub const one = Self{ .x = 1, .y = 1 };
pub const up = Self{ .x = 0, .y = -1 };
pub const down = Self{ .x = 0, .y = 1 };
pub const left = Self{ .x = -1, .y = 0 };
pub const right = Self{ .x = 1, .y = 0 };
