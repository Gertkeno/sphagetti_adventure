const Self = @This();
const Point = @import("Point.zig");

x: i32,
y: i32,
w: u16,
h: u16,

pub fn collides(a: Self, b: Self) bool {
    if (a.x + a.w < b.x) {
        return false;
    } else if (a.x > b.x + b.w) {
        return false;
    }

    if (a.y + a.h < b.y) {
        return false;
    } else if (a.y > b.y + b.h) {
        return false;
    }

    return true;
}

pub fn collides_point(a: Self, b: Point) bool {
    if (a.x + a.w < b.x) {
        return false;
    } else if (a.x > b.x) {
        return false;
    }

    if (a.y + a.h < b.y) {
        return false;
    } else if (a.y > b.y) {
        return false;
    }

    return true;
}

pub fn midpoint(self: Self) Point {
    return Point{
        .x = self.x + self.w / 2,
        .y = self.y + self.h / 2,
    };
}
