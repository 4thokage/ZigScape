const std = @import("std");

pub const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return Point{ .x = x, .y = y };
    }

    pub fn equals(self: *const Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn distanceSquared(self: *const Point, other: Point) i32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return dx * dx + dy * dy;
    }
};

pub fn chebyshevDistance(a: Point, b: Point) u32 {
    const dx = @abs(a.x - b.x);
    const dy = @abs(a.y - b.y);

    return @max(dx, dy);
}
