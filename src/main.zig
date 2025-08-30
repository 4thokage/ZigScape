const rl = @import("raylib");
const std = @import("std");

const Player = @import("player.zig").Player;
const World = @import("world.zig").World;
const Point = @import("utils.zig").Point;

const Config = struct {
    windowWidth: i32 = 320,
    windowHeight: i32 = 180,
    fps: i32 = 60,
    tickDuration: f32 = 0.6,
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

    const tileset = try rl.loadTexture("assets/tileset.png");
    defer rl.unloadTexture(tileset);

    var player = Player.init(allocator, Point.init(2, 2), 28.0);

    var queuedTarget: ?Point = null;
    var tickTimer: f32 = 0;

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();
        tickTimer += dt;

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            const mousePos = rl.getMousePosition();
            const gridX: f32 = mousePos.x / World.TILE_SIZE;
            const gridY: f32 = mousePos.y / World.TILE_SIZE;

            queuedTarget = Point.init(@intFromFloat(gridX), @intFromFloat(gridY));
        }

        //TICK LOOP
        while (tickTimer >= config.tickDuration) : (tickTimer -= config.tickDuration) {

            //movement
            if (queuedTarget) |target| {
                player.setTarget(world, target);
                queuedTarget = null;
            }
            player.consumeNextPathTile();
        }

        world.draw(tileset);
        player.updateVisual(dt);
        player.draw(playerTexture);
    }
}
