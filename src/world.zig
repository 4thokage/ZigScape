const std = @import("std");
const rl = @import("raylib");
const Point = @import("utils.zig").Point;

/// Ground types
pub const GroundTile = enum {
    Grass,
    Dirt,
    Water,
    Stone,
};

/// Object types
pub const ObjectKind = enum {
    None,
    Tree,
    Ore,
    Wall,
    Building,
};

pub const Object = struct {
    kind: ObjectKind,
    variant: u8,
};

/// Tile with layers
pub const Tile = struct {
    ground: GroundTile,
    object: Object,
};

pub const World = struct {
    width: usize,
    height: usize,
    tiles: []Tile,

    pub const TILE_SIZE: i32 = 16;

    /// Initialize world
    pub fn init(allocator: *std.mem.Allocator, width: usize, height: usize) !World {
        var tiles = try allocator.alloc(Tile, width * height);
        for (tiles) |*tile| {
            tile.ground = .Grass;
            tile.object = Object{ .kind = .None, .variant = 0 };
        }

        // Example walls
        for (0..width) |x| {
            tiles[0 * width + x].object = Object{ .kind = .Wall, .variant = 0 };
            tiles[(height - 1) * width + x].object = Object{ .kind = .Wall, .variant = 0 };
        }
        for (0..height) |y| {
            tiles[y * width + 0].object = Object{ .kind = .Wall, .variant = 0 };
            tiles[y * width + (width - 1)].object = Object{ .kind = .Wall, .variant = 0 };
        }

        // Example tree and ore
        tiles[5 * width + 5].object = Object{ .kind = .Tree, .variant = 0 };
        tiles[3 * width + 7].object = Object{ .kind = .Tree, .variant = 1 };
        tiles[8 * width + 2].object = Object{ .kind = .Ore, .variant = 0 };
        tiles[6 * width + 3].object = Object{ .kind = .Ore, .variant = 1 };

        return World{
            .width = width,
            .height = height,
            .tiles = tiles,
        };
    }

    pub fn deinit(self: *World, allocator: *std.mem.Allocator) void {
        allocator.free(self.tiles);
    }

    /// Check if a tile is walkable (no walls)
    pub fn isTileWalkable(self: *const World, pos: Point) bool {
        const uWidth: usize = @intCast(self.width);
        const uHeight: usize = @intCast(self.width);
        if (pos.x < 0 or pos.y < 0 or pos.x >= uWidth or pos.y >= uHeight) return false;

        const ix: usize = @intCast(pos.x);
        const iy: usize = @intCast(pos.y);
        const tile = self.tiles[iy * self.width + ix];
        return tile.object.kind != .Wall;
    }

    /// Get the tile at coordinates
    pub fn getTile(self: *const World, x: usize, y: usize) Tile {
        if (x >= self.width or y >= self.height) return Tile{ .ground = .Grass, .object = Object{ .kind = .None, .variant = 0 } };
        return self.tiles[y * self.width + x];
    }

    /// Draw the world
    pub fn draw(self: *const World, tileset: rl.Texture2D) void {
        for (0..self.width) |x| {
            for (0..self.height) |y| {
                const tile = self.getTile(x, y);
                const px: f32 = @floatFromInt(x * TILE_SIZE);
                const py: f32 = @floatFromInt(y * TILE_SIZE);

                // Draw ground
                rl.drawTextureRec(tileset, getGroundSrcRect(tile.ground), rl.Vector2{ .x = px, .y = py }, rl.Color.ray_white);

                // Draw object if present
                if (tile.object.kind != .None) {
                    rl.drawTextureRec(tileset, getObjectSrcRect(tile.object), rl.Vector2{ .x = px, .y = py }, rl.Color.ray_white);
                }
            }
        }
    }
};

/// Map ground tile to tileset rectangle
fn getGroundSrcRect(tile: GroundTile) rl.Rectangle {
    return switch (tile) {
        .Grass => rl.Rectangle{ .x = 0, .y = 0, .width = 16, .height = 16 },
        .Dirt => rl.Rectangle{ .x = 16, .y = 0, .width = 16, .height = 16 },
        .Stone => rl.Rectangle{ .x = 32, .y = 0, .width = 16, .height = 16 },
        .Water => rl.Rectangle{ .x = 48, .y = 0, .width = 16, .height = 16 },
    };
}

/// Map object tile to tileset rectangle
fn getObjectSrcRect(obj: Object) rl.Rectangle {
    return switch (obj.kind) {
        .Tree => switch (obj.variant) {
            0 => rl.Rectangle{ .x = 0, .y = 16, .width = 16, .height = 16 },
            1 => rl.Rectangle{ .x = 16, .y = 16, .width = 16, .height = 16 },
            else => rl.Rectangle{ .x = 0, .y = 16, .width = 16, .height = 16 },
        },
        .Ore => switch (obj.variant) {
            0 => rl.Rectangle{ .x = 32, .y = 16, .width = 16, .height = 16 },
            1 => rl.Rectangle{ .x = 48, .y = 16, .width = 16, .height = 16 },
            else => rl.Rectangle{ .x = 32, .y = 16, .width = 16, .height = 16 },
        },
        .Wall => rl.Rectangle{ .x = 64, .y = 16, .width = 16, .height = 16 },
        .Building => rl.Rectangle{ .x = 80, .y = 16, .width = 16, .height = 16 },
        .None => rl.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 },
    };
}
