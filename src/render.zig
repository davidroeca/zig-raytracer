const std = @import("std");
const camera = @import("./camera.zig");
const Camera = camera.Camera;
const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = vec3.Color;
const mat = @import("./material.zig");
const Material = mat.Material;
const ray = @import("./ray.zig");
const Ray = ray.Ray;
const hittable = @import("./hittable.zig");
const Sphere = hittable.Sphere;
pub const World = hittable.World;

const MAX_RAY_DEPTH: u8 = 50;

fn rayColor(world: *World, ray_: Ray, depth: u8, rng: std.Random) Color {
    const t_min = 0.001;
    const t_max = std.math.inf(f64);
    if (depth > MAX_RAY_DEPTH) {
        return Color.init(0.0, 0.0, 0.0);
    }
    const opt_hit = world.hit(ray_, t_min, t_max);
    if (opt_hit) |hit| {
        if (hit.material.scatter(ray_, hit, rng)) |scatter| {
            const incoming_color = rayColor(
                world,
                scatter.scattered,
                depth + 1,
                rng,
            );
            return incoming_color.mulVec(scatter.attenuation);
        }
        // Color completely absorbed
        return Color.init(0.0, 0.0, 0.0);
    }
    // Sky gradient: warm white at horizon, deeper blue at zenith
    const unit_direction = ray_.direction.unitVector();
    const t = 0.5 * (unit_direction.y + 1.0);
    const horizon = Color.init(1.0, 0.95, 0.85);
    const zenith = Color.init(0.3, 0.5, 0.9);
    return horizon.mul(1.0 - t).add(zenith.mul(t));
}

pub const SceneConfig = struct {
    image_width: u32,
    image_height: u32,
    samples_per_pixel: u32,
};

pub const default_config = SceneConfig{
    .image_width = 800,
    .image_height = 600,
    // anti-aliasing
    .samples_per_pixel = 20,
};

pub fn setupCamera(config: SceneConfig) Camera {
    return Camera.init(
        Point3.init(0.0, 0.0, 1.5),
        Point3.init(0.0, 0.0, -1.0),
        // 60 degree field of view
        std.math.pi / 3.0,
        @as(f64, @floatFromInt(config.image_width)) / @as(f64, @floatFromInt(config.image_height)),
        0.005,
        2.5,
    );
}

pub fn setupWorld(allocator: std.mem.Allocator) !World {
    var world = try World.init(allocator, 3);
    errdefer world.deinit();
    // Left: matte terracotta sphere
    try world.add_sphere(Sphere.init(Point3.init(-1.2, 0.0, -1.0), 0.5, Material.initLambertian(Color.init(0.8, 0.35, 0.2))));
    // Center: gold metal sphere
    try world.add_sphere(Sphere.init(Point3.init(0.0, 0.0, -1.2), 0.5, Material.initMetal(Color.init(0.85, 0.65, 0.1), 0.1)));
    // Right: glass sphere
    try world.add_sphere(Sphere.init(Point3.init(1.2, 0.0, -1.0), 0.5, Material.initDielectric(1.5)));

    try world.buildBVH();
    return world;
}

/// Render a horizontal strip (rows y_start..y_end) into an RGBA buffer.
/// Buffer must be at least image_width * (y_end - y_start) * 4 bytes.
/// Pixel coordinates use the full image dimensions for correct ray generation.
pub fn renderStrip(
    buffer: [*]u8,
    config: SceneConfig,
    y_start: u32,
    y_end: u32,
    world: *World,
    cam: Camera,
    rng: std.Random,
) void {
    const image_width = config.image_width;
    const image_height = config.image_height;
    const samples_per_pixel = config.samples_per_pixel;

    var y: u32 = y_start;
    while (y < y_end) : (y += 1) {
        var x: u32 = 0;
        while (x < image_width) : (x += 1) {
            // each will be divided by samples_per_pixel to produce color
            var color = Color.init(0.0, 0.0, 0.0);
            var i: u32 = 0;
            while (i < samples_per_pixel) : (i += 1) {
                const u = (@as(f64, @floatFromInt(x)) + rng.float(f64)) / @as(f64, @floatFromInt(image_width - 1));
                const v = (@as(f64, @floatFromInt(y)) + rng.float(f64)) / @as(f64, @floatFromInt(image_height - 1));
                const pixel_ray = cam.getRay(u, v, rng);
                const sample_color = rayColor(world, pixel_ray, 0, rng);
                color = color.add(sample_color);
            }
            color = color.mul(1.0 / @as(f64, @floatFromInt(samples_per_pixel)));

            const offset = ((y - y_start) * image_width + x) * 4;
            buffer[offset] = @intFromFloat(255.999 * color.x);
            buffer[offset + 1] = @intFromFloat(255.999 * color.y);
            buffer[offset + 2] = @intFromFloat(255.999 * color.z);
            buffer[offset + 3] = 255;
        }
    }
}

/// Render the full scene into an RGBA pixel buffer.
/// Buffer must be at least image_width * image_height * 4 bytes.
pub fn renderToBuffer(
    buffer: [*]u8,
    config: SceneConfig,
    world: *World,
    cam: Camera,
    rng: std.Random,
) void {
    renderStrip(buffer, config, 0, config.image_height, world, cam, rng);
}
