const rl = @import("raylib");
const rlm = @import("raylib-math");
const std = @import("std");

const SCREENWIDTH = 800;
const SCREENHEIGHT = 450;

const BALL_VELOCITY = 5;
const BALL_RADIUS = 12;

const PADDLE_LENGTH = 100;
const PADDLE_VELOCITY = 2;
const PADDLE_FRICTION = 0.5;

const PADDLE_1_DEFAULT_POSITION = rl.Vector2.init(10, SCREENHEIGHT / 2 - PADDLE_LENGTH / 2);
const PADDLE_2_DEFAULT_POSITION = rl.Vector2.init(SCREENWIDTH - 10, SCREENHEIGHT / 2 - PADDLE_LENGTH / 2);

const Movable = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
};

const GameState = struct {
    ball: Movable,
    paddle1: Movable,
    paddle2: Movable,
    scores: std.meta.Tuple(&.{ u32, u32 }),
};

fn drawLines(
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

fn movePoints(
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

/// Draw a digit at a given position (top-left corner).
/// Numbers greater than 9 will have the last digit drawn.
fn drawDigit(number: u32, position: rl.Vector2) void {
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

fn update(state: *GameState) void {
    state.paddle1.velocity = rl.Vector2.init(0.0, 0.0);
    state.paddle2.velocity = rl.Vector2.init(0.0, 0.0);

    { // Paddle controls
        // Paddle 1 controls
        if (rl.isKeyDown(.key_w)) {
            state.paddle1.velocity = rlm.vector2Add(
                state.paddle1.velocity,
                rl.Vector2.init(0.0, -1),
            );
        }
        if (rl.isKeyDown(.key_s)) {
            state.paddle1.velocity = rlm.vector2Add(
                state.paddle1.velocity,
                rl.Vector2.init(0.0, 1),
            );
        }
        state.paddle1.velocity = rlm.vector2Normalize(state.paddle1.velocity);
        state.paddle1.velocity = rlm.vector2Scale(state.paddle1.velocity, PADDLE_VELOCITY);
        state.paddle1.position = rlm.vector2Add(
            state.paddle1.position,
            state.paddle1.velocity,
        );
        state.paddle1.position = rlm.vector2Clamp(
            state.paddle1.position,
            rl.Vector2.init(0, 0),
            rl.Vector2.init(SCREENWIDTH, SCREENHEIGHT - PADDLE_LENGTH),
        );

        // Paddle 2 controls
        if (rl.isKeyDown(.key_up)) {
            state.paddle2.velocity = rlm.vector2Add(
                state.paddle2.velocity,
                rl.Vector2.init(0.0, -1),
            );
        }
        if (rl.isKeyDown(.key_down)) {
            state.paddle2.velocity = rlm.vector2Add(
                state.paddle2.velocity,
                rl.Vector2.init(0.0, 1),
            );
        }
        state.paddle2.velocity = rlm.vector2Normalize(state.paddle2.velocity);
        state.paddle2.velocity = rlm.vector2Scale(state.paddle2.velocity, PADDLE_VELOCITY);
        state.paddle2.position = rlm.vector2Add(
            state.paddle2.position,
            state.paddle2.velocity,
        );
        state.paddle2.position = rlm.vector2Clamp(
            state.paddle2.position,
            rl.Vector2.init(0, 0),
            rl.Vector2.init(SCREENWIDTH, SCREENHEIGHT - PADDLE_LENGTH),
        );
    }

    { // Check collision with walls
        if (rl.checkCollisionPointLine(
            state.ball.position,
            rl.Vector2.init(0, 0),
            rl.Vector2.init(SCREENWIDTH, 0),
            BALL_RADIUS,
        )) {
            state.ball.velocity = rlm.vector2Reflect(
                state.ball.velocity,
                rl.Vector2.init(0, 1),
            );
            state.ball.velocity = rlm.vector2Normalize(
                state.ball.velocity,
            );
        }
        if (rl.checkCollisionPointLine(
            state.ball.position,
            rl.Vector2.init(0, SCREENHEIGHT),
            rl.Vector2.init(SCREENWIDTH, SCREENHEIGHT),
            BALL_RADIUS,
        )) {
            state.ball.velocity = rlm.vector2Reflect(
                state.ball.velocity,
                rl.Vector2.init(0, -1),
            );
            state.ball.velocity = rlm.vector2Normalize(
                state.ball.velocity,
            );
        }
    }

    { // Check collision with paddles
        if (rl.checkCollisionPointLine(
            state.ball.position,
            state.paddle1.position,
            rlm.vector2Add(state.paddle1.position, rl.Vector2.init(0, PADDLE_LENGTH)),
            BALL_RADIUS,
        )) {

            // Bounce ball on paddle
            state.ball.velocity = rlm.vector2Reflect(
                state.ball.velocity,
                rl.Vector2.init(1, 0),
            );
            // state.ball.velocity = rlm.vector2Normalize(
            //     state.ball.velocity,
            // );

            // Add paddle velocity to ball velocity with friction
            const scaledVelocity = rlm.vector2Scale(
                state.paddle1.velocity,
                PADDLE_FRICTION,
            );
            state.ball.velocity = rlm.vector2Add(
                state.ball.velocity,
                scaledVelocity,
            );
            state.ball.position = rlm.vector2Add(
                state.ball.position,
                state.ball.velocity,
            );
        }

        if (rl.checkCollisionPointLine(
            state.ball.position,
            state.paddle2.position,
            rlm.vector2Add(state.paddle2.position, rl.Vector2.init(0, PADDLE_LENGTH)),
            BALL_RADIUS,
        )) {
            // Bounce ball on paddle
            state.ball.velocity = rlm.vector2Reflect(
                state.ball.velocity,
                rl.Vector2.init(-1, 0),
            );
            // state.ball.velocity = rlm.vector2Normalize(
            //     state.ball.velocity,
            // );

            // Add paddle velocity to ball velocity with friction
            const scaledVelocity = rlm.vector2Scale(
                state.paddle2.velocity,
                PADDLE_FRICTION,
            );
            state.ball.velocity = rlm.vector2Add(
                state.ball.velocity,
                scaledVelocity,
            );
            state.ball.position = rlm.vector2Add(
                state.ball.position,
                state.ball.velocity,
            );
        }
    }

    { // Check collision with goals
        if (rl.checkCollisionPointLine(
            state.ball.position,
            rl.Vector2.init(0, 0),
            rl.Vector2.init(0, SCREENHEIGHT),
            BALL_RADIUS,
        )) {
            state.ball.position = rl.Vector2.init(SCREENWIDTH / 2, SCREENHEIGHT / 2);
            state.ball.velocity = rl.Vector2.init(-BALL_VELOCITY, 0.0);
            state.scores = .{ state.scores[0], state.scores[1] + 1 };
            state.paddle1.position = PADDLE_1_DEFAULT_POSITION;
            state.paddle2.position = PADDLE_2_DEFAULT_POSITION;
        }
        if (rl.checkCollisionPointLine(
            state.ball.position,
            rl.Vector2.init(SCREENWIDTH, 0),
            rl.Vector2.init(SCREENWIDTH, SCREENHEIGHT),
            BALL_RADIUS,
        )) {
            state.ball.position = rl.Vector2.init(SCREENWIDTH / 2, SCREENHEIGHT / 2);
            state.ball.velocity = rl.Vector2.init(BALL_VELOCITY, 0.0);
            state.scores = .{ state.scores[0] + 1, state.scores[1] };
            state.paddle1.position = PADDLE_1_DEFAULT_POSITION;
            state.paddle2.position = PADDLE_2_DEFAULT_POSITION;
        }
    }

    // Scale ball velocity
    state.ball.velocity = rlm.vector2Normalize(state.ball.velocity);
    state.ball.velocity = rlm.vector2Scale(
        state.ball.velocity,
        BALL_VELOCITY,
    );

    // Move ball
    state.ball.position = rlm.vector2Add(
        state.ball.position,
        state.ball.velocity,
    );
}

fn drawLogo() void {
    {
        const center = rl.Vector2.init(
            SCREENWIDTH / 2,
            SCREENHEIGHT / 2,
        );
        const p1 = rlm.vector2Add(
            center,
            rl.Vector2.init(-PADDLE_LENGTH / 2, -PADDLE_LENGTH / 2),
        );
        const p2 = rlm.vector2Add(
            center,
            rl.Vector2.init(PADDLE_LENGTH / 2, -PADDLE_LENGTH / 2),
        );

        // Ball
        rl.drawCircleLinesV(
            center,
            BALL_RADIUS,
            rl.Color.red,
        );

        // Paddle 1
        rl.drawLineV(
            p1,
            rlm.vector2Add(
                p1,
                rl.Vector2.init(0, PADDLE_LENGTH),
            ),
            rl.Color.green,
        );

        // Paddle 2
        rl.drawLineV(
            p2,
            rlm.vector2Add(
                p2,
                rl.Vector2.init(0, PADDLE_LENGTH),
            ),
            rl.Color.green,
        );
    }
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    var state = GameState{
        .ball = Movable{
            .position = rl.Vector2.init(SCREENWIDTH / 2, SCREENHEIGHT / 2),
            .velocity = rl.Vector2.init(BALL_VELOCITY, 0.0),
        },
        .paddle1 = Movable{
            .position = PADDLE_1_DEFAULT_POSITION,
            .velocity = rl.Vector2.init(0.0, 0.0),
        },
        .paddle2 = Movable{
            .position = PADDLE_2_DEFAULT_POSITION,
            .velocity = rl.Vector2.init(0.0, 0.0),
        },
        .scores = .{ 0, 0 },
    };

    rl.initWindow(SCREENWIDTH, SCREENHEIGHT, "plong");
    rl.setWindowIcon(rl.loadImage("resources/raylib_logo.png")); // Load a window icon
    rl.setWindowPosition(100, 100);
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        update(&state);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        { // Ball
            rl.drawCircleLinesV(
                state.ball.position,
                BALL_RADIUS,
                rl.Color.red,
            );
        }

        { // Paddle 1
            rl.drawLineV(
                state.paddle1.position,
                rlm.vector2Add(
                    state.paddle1.position,
                    rl.Vector2.init(0, PADDLE_LENGTH),
                ),
                rl.Color.green,
            );
        }

        { // Paddle 2
            rl.drawLineV(
                state.paddle2.position,
                rlm.vector2Add(
                    state.paddle2.position,
                    rl.Vector2.init(0, PADDLE_LENGTH),
                ),
                rl.Color.green,
            );
        }

        // Scores
        drawDigit(state.scores[0], rl.Vector2.init(SCREENWIDTH / 4, 10));
        drawDigit(state.scores[1], rl.Vector2.init(3 * SCREENWIDTH / 4, 10));

        // rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
        //----------------------------------------------------------------------------------
    }
}
