const std = @import("std");
const render = @import("./render.zig");

fn writeColor(writer: anytype, r: u8, g: u8, b: u8) !void {
    try writer.print("{d} {d} {d}\n", .{ r, g, b });
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Set up random number generator
    var prng = std.Random.DefaultPrng.init(420);
    const rng = prng.random();

    const config = render.default_config;
    const cam = render.setupCamera(config);

    // initialize allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var world = try render.setupWorld(allocator);
    defer world.deinit();

    // Render into RGBA buffer
    const pixel_count = config.image_width * config.image_height;
    const buffer = try allocator.alloc(u8, pixel_count * 4);
    render.renderToBuffer(buffer.ptr, config, &world, cam, rng);

    // Write PPM output
    try stdout.print("P3\n{d} {d}\n255\n", .{ config.image_width, config.image_height });
    for (0..pixel_count) |i| {
        const offset = i * 4;
        try writeColor(stdout, buffer[offset], buffer[offset + 1], buffer[offset + 2]);
    }
    try stdout.flush();
}
