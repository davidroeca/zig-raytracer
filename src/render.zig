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

fn hsvToRgb(h: f64, s: f64, v: f64) Color {
    // All values must be in [0, 1]
    const sector = @floor(h * 6.0);

    // fractional part of sector
    const f = h * 6.0 - sector;

    const p = v * (1.0 - s);
    const q = v * (1.0 - f * s);
    const t = v * (1.0 - (1.0 - f) * s);

    if (0.0 <= sector and sector < 1.0) {
        return Color.init(v, t, p);
    } else if (1.0 <= sector and sector < 2.0) {
        return Color.init(q, v, p);
    } else if (2.0 <= sector and sector < 3.0) {
        return Color.init(p, v, t);
    } else if (3.0 <= sector and sector < 4.0) {
        return Color.init(p, q, v);
    } else if (4.0 <= sector and sector < 5.0) {
        return Color.init(t, p, v);
    } else {
        return Color.init(v, p, q);
    }
}

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
    // rainbow spiral
    const unit_direction = ray_.direction.unitVector();
    const normalized_angle = std.math.atan2(unit_direction.y, unit_direction.x) + std.math.pi;
    // [0, 1]
    const hue = normalized_angle / (2.0 * std.math.pi);
    // Set ray color based on y direction of the ray
    return hsvToRgb(hue, 1.0, 1.0);
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
        Point3.init(0.0, 0.0, 1.0),
        Point3.init(0.0, 0.0, -2.0),
        // 90 degree field of view
        std.math.pi / 2.0,
        @as(f64, @floatFromInt(config.image_width)) / @as(f64, @floatFromInt(config.image_height)),
        0.01,
        2.0,
    );
}

pub fn setupWorld(allocator: std.mem.Allocator) !World {
    // add spheres to world
    var world = try World.init(allocator, 4);
    errdefer world.deinit();
    // Gold sphere
    try world.add_sphere(Sphere.init(Point3.init(0.0, 0.0, -3.0), 1, Material.initMetal(Color.init(0.937, 0.749, 0.016), 0.5)));
    // Pink sphere
    try world.add_sphere(Sphere.init(Point3.init(-1.3, 0.0, -1.5), 0.3, Material.initLambertian(Color.init(1.000, 0.412, 0.706))));
    // Water sphere
    try world.add_sphere(Sphere.init(Point3.init(1.3, 0.0, -1.25), 0.3, Material.initDielectric(1.33)));
    // Glass sphere
    try world.add_sphere(Sphere.init(Point3.init(1.3, 0.5, -2.0), 0.3, Material.initDielectric(1.52)));

    try world.buildBVH();
    return world;
}

/// Render the scene into an RGBA pixel buffer.
/// Buffer must be at least image_width * image_height * 4 bytes.
pub fn renderToBuffer(
    buffer: [*]u8,
    config: SceneConfig,
    world: *World,
    cam: Camera,
    rng: std.Random,
) void {
    const image_width = config.image_width;
    const image_height = config.image_height;
    const samples_per_pixel = config.samples_per_pixel;

    var y: u32 = 0;
    while (y < image_height) : (y += 1) {
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

            const offset = (y * image_width + x) * 4;
            buffer[offset] = @intFromFloat(255.999 * color.x);
            buffer[offset + 1] = @intFromFloat(255.999 * color.y);
            buffer[offset + 2] = @intFromFloat(255.999 * color.z);
            buffer[offset + 3] = 255;
        }
    }
}
