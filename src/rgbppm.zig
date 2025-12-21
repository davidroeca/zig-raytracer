const std = @import("std");

pub fn outputPPM(width: u32, height: u32) !void {
    if (width == 0 or height == 0) {
        return;
    }
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("P3\n{d} {d}\n255\n", .{ width, height });
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const r = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(x + 1)) / @as(f64, @floatFromInt(width)) * 255.0)));
            const g = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(y + 1)) / @as(f64, @floatFromInt(height)) * 255.0)));
            const b: i32 = 0;
            try stdout.print("{d} {d} {d}\n", .{ r, g, b });
        }
    }
    try stdout.flush();
}

pub fn main() !void {
    try outputPPM(800, 600);
}
