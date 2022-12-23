const w4 = @import("wasm4.zig");
const Self = @This();

width: u8,
height: u8,
data: [*]const u8,
flags: u8 = w4.BLIT_2BPP,

pub fn draw_br(self: Self, x: i32, y: i32) void {
    w4.blit(self.data, x - self.width, y - self.height, self.width, self.height, self.flags);
}

pub fn draw_bl(self: Self, x: i32, y: i32) void {
    w4.blit(self.data, x, y - self.height, self.width, self.height, self.flags);
}
