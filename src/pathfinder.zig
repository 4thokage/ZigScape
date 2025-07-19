const std = @import("std");

const World = @import("world.zig").World;
const utils = @import("utils.zig");

const Node = struct {
    pos: utils.Point,
    g_cost: u32,
    h_cost: u32,
    f_cost: u32,
    parent: ?*Node,
};

/// Self explanatory
const merda = error{
    PathNotFound,
};

/// Finds the shortest path between two points using A*.
/// Returns a slice of points or an error if no path exists.
///
/// Params:
/// - `start`: Starting point on the grid.
/// - `goal`: Destination point.
/// - `world`: The world grid (with walkable/unwalkable tiles).
///
/// Errors:
/// - `PathNotFound`: If no path exists between start and goal.
///
pub fn findPath(start: utils.Point, goal: utils.Point, world: World) ![]utils.Point {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit(); //we are crazy and we dont need debug!

    const bytes = try allocator.alloc(u8, 16 * 1024);
    defer allocator.free(bytes);

    var openList = std.ArrayList(Node).init(allocator);
    defer openList.deinit();
    try openList.append(Node{
        .pos = start,
        .g_cost = 0,
        .h_cost = utils.chebyshevDistance(start, goal),
        .f_cost = utils.chebyshevDistance(start, goal),
        .parent = null,
    });

    var closedList = std.ArrayList(Node).init(allocator);
    defer closedList.deinit();

    const debug = world.getTile(1, 1);
    std.debug.print("The TileType is {}\n", .{debug});

    return merda.PathNotFound;
}
