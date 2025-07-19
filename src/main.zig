const rl = @import("raylib");
const std = @import("std");

const Player = @import("player.zig").Player;
const World = @import("world.zig").World;
const Point = @import("utils.zig").Point;

const Config = struct {
    windowWidth: i32 = 320,
    windowHeight: i32 = 180,
    fps: i32 = 60,
};

pub fn main() !void {
    const config = Config{};

    rl.setConfigFlags(rl.ConfigFlags{
        .window_undecorated = true,
        .window_always_run = true,
        .window_topmost = true,
    });
    rl.initWindow(config.windowWidth, config.windowHeight, "Click Scape");
    defer rl.closeWindow();

    const displayWidth = rl.getMonitorWidth(0);
    const displayHeight = rl.getMonitorHeight(0);

    const winPosX = displayWidth - config.windowWidth;
    const winPosY = displayHeight - config.windowHeight;
    rl.setWindowPosition(winPosX, winPosY);

    rl.setTargetFPS(config.fps);

    var allocator = std.heap.page_allocator;
    var world = try World.init(&allocator, 100, 100);
    defer world.deinit(&allocator);

    const playerTexture = try rl.loadTexture("assets/hero/00_hero_naked.png");
    defer rl.unloadTexture(playerTexture);

    var player = Player.init(allocator, Point.init(2, 2), 20.0);
    var targetGrid: ?Point = null;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);
        world.draw();

        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            const mousePos = rl.getMousePosition();
            const gridX: f32 = mousePos.x / World.TILE_SIZE;
            const gridY: f32 = mousePos.y / World.TILE_SIZE;

            const targetPoint = Point.init(@intFromFloat(gridX), @intFromFloat(gridY));

            targetGrid = targetPoint;

            player.setTarget(world, targetPoint);
        }

        //DEBUG: Draw highlight on the target grid cell, if any
        if (targetGrid) |pt| {
            const rect = rl.Rectangle{
                .x = @as(f32, @floatFromInt(pt.x)) * World.TILE_SIZE,
                .y = @as(f32, @floatFromInt(pt.y)) * World.TILE_SIZE,
                .width = World.TILE_SIZE,
                .height = World.TILE_SIZE,
            };
            rl.drawRectangleLinesEx(rect, 2, rl.Color.green);
        }
        player.update(&world);
        player.draw(playerTexture);
    }
}
