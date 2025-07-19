const rl = @import("raylib");

pub const Animation = struct {
    first: u8,
    last: u8,
    cur: u8,
    speed: f32,
    duration_left: f32,
    mode: Mode,

    pub const Mode = enum {
        Repeating,
        OneShot,
    };

    pub fn update(self: *Animation) void {
        const dt = rl.getFrameTime();
        self.duration_left -= dt;

        if (self.duration_left <= 0.0) {
            self.duration_left = self.speed;
            self.cur += 1;

            if (self.cur > self.last) {
                switch (self.mode) {
                    .Repeating => self.cur = self.first,
                    .OneShot => self.cur = self.last,
                }
            }
        }
    }

    pub fn frame(self: *const Animation, framesPerRow: u8) rl.Rectangle {
        const x = (self.cur % framesPerRow) * 16;
        const y = (self.cur / framesPerRow) * 16;

        return rl.Rectangle{
            .x = @floatFromInt(x),
            .y = @floatFromInt(y),
            .width = 16.0,
            .height = 16.0,
        };
    }
};
