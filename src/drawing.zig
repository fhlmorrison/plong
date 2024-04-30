const rl = @import("raylib");
const rlm = @import("raylib-math");

/// Draw a digit at a given position (top-left corner).
/// Numbers greater than 9 will have the last digit drawn.
pub fn drawDigit(number: u32, position: rl.Vector2) void {
    const digitScale = 10;

    const digitMasks = [10][7]bool{
        // 0
        .{ true, true, true, true, true, true, false },
        // 1
        .{ false, true, true, false, false, false, false },
        // 2
        .{ true, true, false, true, true, false, true },
        // 3
        .{ true, true, true, true, false, false, true },
        // 4
        .{ false, true, true, false, false, true, true },
        // 5
        .{ true, false, true, true, false, true, true },
        // 6
        .{ true, false, true, true, true, true, true },
        // 7
        .{ true, true, true, false, false, false, false },
        // 8
        .{ true, true, true, true, true, true, true },
        // 9
        .{ true, true, true, true, false, true, true },
    };

    const SEVEN_SEGMENT_POINTS = comptime [6]rl.Vector2{
        rl.Vector2.init(0, 0),
        rl.Vector2.init(1, 0),
        rl.Vector2.init(1, 1),
        rl.Vector2.init(1, 2),
        rl.Vector2.init(0, 2),
        rl.Vector2.init(0, 1),
    };

    const SEVEN_SEGMENT_LINES = comptime [7][2]rl.Vector2{
        .{ SEVEN_SEGMENT_POINTS[0], SEVEN_SEGMENT_POINTS[1] },
        .{ SEVEN_SEGMENT_POINTS[1], SEVEN_SEGMENT_POINTS[2] },
        .{ SEVEN_SEGMENT_POINTS[2], SEVEN_SEGMENT_POINTS[3] },
        .{ SEVEN_SEGMENT_POINTS[3], SEVEN_SEGMENT_POINTS[4] },
        .{ SEVEN_SEGMENT_POINTS[4], SEVEN_SEGMENT_POINTS[5] },
        .{ SEVEN_SEGMENT_POINTS[5], SEVEN_SEGMENT_POINTS[0] },
        .{ SEVEN_SEGMENT_POINTS[5], SEVEN_SEGMENT_POINTS[2] },
    };

    const digit = digitMasks[number % 10];

    for (SEVEN_SEGMENT_LINES, digit) |line, mask| {
        if (mask) {
            rl.drawLineV(
                rlm.vector2Add(rlm.vector2Scale(line[0], digitScale), position),
                rlm.vector2Add(rlm.vector2Scale(line[1], digitScale), position),
                rl.Color.white,
            );
        }
    }
}

pub fn drawLines(
    /// Points to draw lines between.
    points: []rl.Vector2,
    /// Color of the lines.
    color: rl.Color,
    /// If true, the last point will be connected to the first point.
    wrap: bool,
) void {
    const max = if (wrap) {
        points.len;
    } else {
        points.len - 1;
    };
    var i: u32 = 0;
    while (i < max) : (i += 1) {
        const p1 = points[i];
        const p2 = points[(i + 1) % points.len];
        rl.drawLineV(p1, p2, color);
    }
}

pub fn movePoints(
    points: []rl.Vector2,
    position: rl.Vector2,
) []rl.Vector2 {
    var newPoints = []rl.Vector2{ .len = points.len };
    var i: u32 = 0;
    while (i < points.len) : (i += 1) {
        newPoints[i] = rlm.vector2Add(points[i], position);
    }
    return newPoints;
}
