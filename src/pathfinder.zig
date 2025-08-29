// pathfinder.zig
const std = @import("std");
const World = @import("world.zig").World;
const utils = @import("utils.zig");

const Point = utils.Point;

const directions = [_][2]i32{
    .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
    .{ -1, 0 },  .{ 1, 0 },  .{ -1, 1 },
    .{ 0, 1 },   .{ 1, 1 },
};

fn keyFromPoint(p: Point) u64 {
    // Pack signed i32s into a u64 key (bit-cast keeps sign bits intact).
    const ux: u32 = @bitCast(p.x);
    const uy: u32 = @bitCast(p.y);
    return (@as(u64, ux) << 32) | uy;
}

fn pointFromKey(k: u64) Point {
    const ux: u32 = @truncate(k >> 32);
    const uy: u32 = @truncate(k & 0xffff_ffff);
    return Point.init(@bitCast(ux), @bitCast(uy));
}

fn isWalkable(world: *const World, p: Point) bool {
    return world.isTileWalkable(p);
}

// Prevent moving diagonally through blocked corners: if moving from A to B diagonally,
// require both intermediate cardinal tiles to be walkable (A -> (Bx,Ay)) AND (A -> (Ax,By)).
fn diagonalBlocked(world: *const World, from: Point, to: Point) bool {
    const dx = to.x - from.x;
    const dy = to.y - from.y;
    if (@abs(dx) != 1 or @abs(dy) != 1) return false;

    const stepX = Point.init(from.x + dx, from.y);
    const stepY = Point.init(from.x, from.y + dy);
    // If either of the cardinal steps is blocked, disallow the diagonal.
    return !isWalkable(world, stepX) or !isWalkable(world, stepY);
}

const Node = struct {
    pos: Point,
    g: u32, // cost from start
    h: u32, // heuristic to goal
    f: u32, // g + h
    // We don't store parent pointers here (ArrayList can move). We keep cameFrom in a hashmap.
};

fn lessThan(_: void, a: Node, b: Node) std.math.Order {
    // Min-heap: prefer lower f; tie-break on lower h (straighter paths).
    if (a.f < b.f) return .lt;
    if (a.f > b.f) return .gt;
    if (a.h < b.h) return .lt;
    if (a.h > b.h) return .gt;
    return .eq;
}

/// Public API: A* with Chebyshev heuristic + 8-neighborhood.
/// Returns an owned slice allocated from page_allocator. Caller should free it.
/// Error:
/// - error.PathNotFound if no path exists.
pub const PathfinderError = error{PathNotFound};

pub fn findPath(start: Point, goal: Point, world: World) ![]Point {
    // Early outs
    if (start.equals(goal)) {
        // Single-tile path
        var one = try std.heap.page_allocator.alloc(Point, 1);
        one[0] = start;
        return one;
    }
    if (!isWalkable(&world, goal)) return PathfinderError.PathNotFound;

    const allocator = std.heap.page_allocator;

    // Open set: priority queue by f-cost.
    var open = std.PriorityQueue(Node, void, lessThan).init(allocator, {});
    defer open.deinit();

    // gScore (best known cost to a node)
    var gScore = std.AutoHashMap(u64, u32).init(allocator);
    defer gScore.deinit();

    // cameFrom (child key -> parent key)
    var cameFrom = std.AutoHashMap(u64, u64).init(allocator);
    defer cameFrom.deinit();

    // Closed set (visited)
    var closed = std.AutoHashMap(u64, void).init(allocator);
    defer closed.deinit();

    const start_key = keyFromPoint(start);
    const goal_key = keyFromPoint(goal);

    const h0 = utils.heuristic(start, goal);
    try open.add(Node{ .pos = start, .g = 0, .h = h0, .f = h0 });
    try gScore.put(start_key, 0);

    // Main A* loop
    while (open.count() > 0) {
        const current = open.remove(); // lowest f (and h tie-break)
        const cur_key = keyFromPoint(current.pos);

        if (!closed.contains(cur_key)) {
            try closed.put(cur_key, {});
        }

        if (cur_key == goal_key) {
            // Reconstruct path
            var rev = std.ArrayList(Point).init(allocator);
            defer rev.deinit();

            var trace_key: ?u64 = cur_key;
            while (trace_key) |k| {
                try rev.append(pointFromKey(k));
                trace_key = cameFrom.get(k);
            }

            // Reverse into owned slice
            const count = rev.items.len;
            var path = try allocator.alloc(Point, count);
            var i: usize = 0;
            while (i < count) : (i += 1) {
                path[i] = rev.items[count - 1 - i];
            }
            return path;
        }

        // Explore neighbors (8-way)
        for (directions) |d| {
            const nx = current.pos.x + d[0];
            const ny = current.pos.y + d[1];
            const npos = Point.init(nx, ny);
            const nkey = keyFromPoint(npos);

            // Skip if blocked or diagonal corner-cut
            if (!isWalkable(&world, npos)) continue;
            if (diagonalBlocked(&world, current.pos, npos)) continue;

            if (closed.contains(nkey)) continue;

            // Movement cost: 1 per step (Chebyshev metric).
            const tentative_g = current.g + 1;

            const prev_g_opt = gScore.get(nkey);
            if (prev_g_opt) |prev_g| {
                if (tentative_g >= prev_g) {
                    // Not a better path—skip
                    continue;
                }
            }

            // This path to neighbor is better (or neighbor unseen)
            try cameFrom.put(nkey, cur_key);
            try gScore.put(nkey, tentative_g);

            const h = utils.heuristic(npos, goal);
            const f = tentative_g + h;

            // We can push duplicates; worse ones will be ignored due to gScore check.
            try open.add(Node{ .pos = npos, .g = tentative_g, .h = h, .f = f });
        }
    }

    return PathfinderError.PathNotFound;
}
