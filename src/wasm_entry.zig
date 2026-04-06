const std = @import("std");
const render = @import("./render.zig");

const page_alloc = std.heap.page_allocator;
var arena = std.heap.ArenaAllocator.init(page_alloc);
var world: ?render.World = null;
var pixel_buffer: ?[*]u8 = null;
var current_width: u32 = 0;
var current_height: u32 = 0;

export fn getBufferPointer() ?[*]u8 {
    return pixel_buffer;
}

export fn getBufferSize() u32 {
    return current_width * current_height * 4;
}

export fn renderScene(width: u32, height: u32, samples_per_pixel: u32) void {
    // Re-allocate pixel buffer if dimensions changed (owned by page_allocator)
    if (width != current_width or height != current_height) {
        if (pixel_buffer) |buf| {
            page_alloc.free(buf[0 .. current_width * current_height * 4]);
        }
        const buf = page_alloc.alloc(u8, width * height * 4) catch return;
        pixel_buffer = buf.ptr;
        current_width = width;
        current_height = height;
    }

    // Set up world on first call (owned by arena)
    if (world == null) {
        world = render.setupWorld(arena.allocator()) catch return;
    }

    const config = render.SceneConfig{
        .image_width = width,
        .image_height = height,
        .samples_per_pixel = samples_per_pixel,
    };
    const cam = render.setupCamera(config);

    var prng = std.Random.DefaultPrng.init(420);
    const rng = prng.random();

    render.renderToBuffer(pixel_buffer.?, config, &world.?, cam, rng);
}
