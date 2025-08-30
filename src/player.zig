const std = @import("std");
const rl = @import("raylib");

const Animation = @import("animation.zig").Animation;
const World = @import("world.zig").World;
const Point = @import("utils.zig").Point;
const Pathfinder = @import("pathfinder.zig");

pub const Player = struct {
    x: f32,
    y: f32,
    speed: f32,
    true_tile: Point,
    target_tile: Point,
    path: []Point,
    allocator: std.mem.Allocator,
    state: PlayerState,
    animations: AnimationSet,
    active_animation: *Animation,

    pub const PlayerState = enum {
        Idle,
        WalkUp,
        WalkDown,
        WalkLeft,
        WalkRight,
    };

    pub const AnimationSet = struct {
        idle: Animation,
        walk_up: Animation,
        walk_down: Animation,
        walk_left: Animation,
        walk_right: Animation,
    };

    pub fn init(allocator: std.mem.Allocator, start_tile: Point, speed: f32) Player {
        const start_x: f32 = @floatFromInt(start_tile.x * World.TILE_SIZE);
        const start_y: f32 = @floatFromInt(start_tile.y * World.TILE_SIZE);

        var anims = AnimationSet{
            .idle = Animation{ .first = 0, .last = 2, .cur = 0, .speed = 0.2, .duration_left = 0.2, .mode = Animation.Mode.Repeating },
            .walk_down = Animation{ .first = 3, .last = 5, .cur = 3, .speed = 0.1, .duration_left = 0.1, .mode = Animation.Mode.Repeating },
            .walk_left = Animation{ .first = 6, .last = 8, .cur = 6, .speed = 0.1, .duration_left = 0.1, .mode = Animation.Mode.Repeating },
            .walk_right = Animation{ .first = 9, .last = 11, .cur = 9, .speed = 0.1, .duration_left = 0.1, .mode = Animation.Mode.Repeating },
            .walk_up = Animation{ .first = 12, .last = 14, .cur = 12, .speed = 0.1, .duration_left = 0.1, .mode = Animation.Mode.Repeating },
        };

        return Player{
            .x = start_x,
            .y = start_y,
            .speed = speed,
            .true_tile = start_tile,
            .target_tile = start_tile,
            .path = &[_]Point{},
            .allocator = allocator,
            .state = PlayerState.Idle,
            .animations = anims,
            .active_animation = &anims.idle,
        };
    }

    // Queue a path to move along
    pub fn setTarget(self: *Player, world: World, grid_target: Point) void {
        if (Pathfinder.findPath(self.true_tile, grid_target, world)) |p| {
            self.path = p;
            self.target_tile = self.path[0];
        } else |_| {
            self.path = &[_]Point{};
            self.target_tile = self.true_tile;
        }
    }

    // Consume the next tile in the path — called per tick
    pub fn consumeNextPathTile(self: *Player) void {
        if (self.path.len == 0) return;

        // Advance logical target
        self.true_tile = self.path[0];
        self.path = self.path[1..];

        // x/y are still visual, will interpolate to new target
        self.target_tile = self.true_tile;
    }

    // Interpolate sprite smoothly toward target_tile every frame
    pub fn updateVisual(self: *Player, dt: f32) void {
        const target_px: f32 = @floatFromInt(self.target_tile.x * World.TILE_SIZE);
        const target_py: f32 = @floatFromInt(self.target_tile.y * World.TILE_SIZE);

        const dx = target_px - self.x;
        const dy = target_py - self.y;
        const distance = @sqrt(dx * dx + dy * dy);

        if (distance > 0.0) {
            // move exactly 1 tile per tick
            const tilesPerTick: f32 = 1.0;
            const move_speed = (World.TILE_SIZE * tilesPerTick) / 0.6;
            const step = move_speed * dt;

            if (step < distance) {
                self.x += dx / distance * step;
                self.y += dy / distance * step;
            } else {
                self.x = target_px;
                self.y = target_py;
            }

            // update state for animation
            if (@abs(dx) > @abs(dy)) {
                self.state = if (dx > 0) PlayerState.WalkRight else PlayerState.WalkLeft;
            } else {
                self.state = if (dy > 0) PlayerState.WalkDown else PlayerState.WalkUp;
            }
        } else {
            self.state = PlayerState.Idle;
        }

        self.active_animation = switch (self.state) {
            .Idle => &self.animations.idle,
            .WalkUp => &self.animations.walk_up,
            .WalkDown => &self.animations.walk_down,
            .WalkLeft => &self.animations.walk_left,
            .WalkRight => &self.animations.walk_right,
        };
        self.active_animation.update();
    }

    pub fn draw(self: *Player, texture: rl.Texture2D) void {
        const frame = self.active_animation.frame(15);

        rl.drawTexturePro(
            texture,
            frame,
            rl.Rectangle{
                .x = self.x,
                .y = self.y,
                .width = 16,
                .height = 16,
            },
            rl.Vector2{ .x = 0, .y = 0 },
            0.0,
            rl.Color.white,
        );

        // Highlight true tile
        const tile_rect = rl.Rectangle{
            .x = @floatFromInt(self.true_tile.x * World.TILE_SIZE),
            .y = @floatFromInt(self.true_tile.y * World.TILE_SIZE),
            .width = World.TILE_SIZE,
            .height = World.TILE_SIZE,
        };
        rl.drawRectangleLinesEx(tile_rect, 1, rl.Color.red);
    }
};
