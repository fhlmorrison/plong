// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const rlm = @import("raylib-math");

const VELOCITY = 1;

const Movable = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
};

const GameState = struct {
    circle: Movable,
};

fn update(state: *GameState) void {
    state.circle.velocity = rl.Vector2.init(0.0, 0.0);
    if (rl.isKeyDown(.key_a)) {
        state.circle.velocity = rlm.vector2Add(state.circle.velocity, rl.Vector2.init(-1, 0.0));
    }
    if (rl.isKeyDown(.key_d)) {
        state.circle.velocity = rlm.vector2Add(state.circle.velocity, rl.Vector2.init(1, 0.0));
    }
    if (rl.isKeyDown(.key_w)) {
        state.circle.velocity = rlm.vector2Add(state.circle.velocity, rl.Vector2.init(0.0, -1));
    }
    if (rl.isKeyDown(.key_s)) {
        state.circle.velocity = rlm.vector2Add(state.circle.velocity, rl.Vector2.init(0.0, 1));
    }

    state.circle.velocity = rlm.vector2Normalize(state.circle.velocity);
    state.circle.velocity = rlm.vector2Scale(state.circle.velocity, VELOCITY);

    state.circle.position = rlm.vector2Add(state.circle.position, state.circle.velocity);
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    // const scaleFactor = 1.0;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var state = GameState{ .circle = Movable{ .position = rl.Vector2.init(screenWidth / 2, screenHeight / 2), .velocity = rl.Vector2.init(1.0, 0.0) } };

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

        rl.drawCircleLinesV(state.circle.position, 12.0, rl.Color.red);

        // rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
        //----------------------------------------------------------------------------------
    }
}
