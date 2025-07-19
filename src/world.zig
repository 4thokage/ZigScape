const std = @import("std");

const rl = @import("raylib");

const Point = @import("utils.zig").Point;

/// Types of tiles
pub const TileType = enum {
    Empty, // walkable
    Wall, // blocked
};

/// World grid
pub const World = struct {
    width: usize,
    height: usize,
    tiles: []TileType,

    pub const TILE_SIZE = 16;

    /// Initialize with empty tiles
    pub fn init(allocator: *std.mem.Allocator, width: usize, height: usize) !World {
        var tiles = try allocator.alloc(TileType, width * height);
        for (tiles) |*tile| {
            tile.* = TileType.Empty;
        }

        // Add a test wall rectangle
        for (5..6) |x| {
            for (3..10) |y| {
                tiles[y * width + x] = TileType.Wall;
            }
        }

        return World{
            .width = width,
            .height = height,
            .tiles = tiles,
        };
    }

    /// Free memory
    pub fn deinit(self: *World, allocator: *std.mem.Allocator) void {
        allocator.free(self.tiles);
    }

    /// Get tile at grid coordinates
    pub fn getTile(self: *const World, x: usize, y: usize) TileType {
        if (x >= self.width or y >= self.height) return TileType.Wall; // out of bounds = blocked
        return self.tiles[y * self.width + x];
    }

    pub fn isTileWalkable(self: *const World, tile: Point) bool {
        if (tile.x < 0 or tile.y < 0 or tile.x >= self.width or tile.y >= self.height) {
            return false; // Out of bounds
        }
        return self.getTile(@as(usize, @intCast(tile.x)), @as(usize, @intCast(tile.y))) != TileType.Wall;
    }

    /// Draw grid and tiles
    pub fn draw(self: *const World) void {
        for (0..self.width) |x| {
            for (0..self.height) |y| {
                const rect = rl.Rectangle{
                    .x = @floatFromInt(x * TILE_SIZE),
                    .y = @floatFromInt(y * TILE_SIZE),
                    .width = TILE_SIZE,
                    .height = TILE_SIZE,
                };

                const color = switch (self.getTile(x, y)) {
                    .Empty => rl.Color.ray_white,
                    .Wall => rl.Color.black,
                };
                rl.drawRectangleRec(rect, color);
                rl.drawRectangleLinesEx(rect, 1, rl.Color.black);
            }
        }
    }
};
