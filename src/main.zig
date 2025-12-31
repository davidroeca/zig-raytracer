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
const HitRecord = hittable.HitRecord;
const World = hittable.World;

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

fn hitSphere(center: Point3, radius: f64, ray_: Ray) ?HitRecord {
    const sphere = Sphere.init(center, radius);
    return sphere.hit(ray_);
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

fn writeColor(writer: anytype, color: Color) !void {
    const r = @as(u8, @intFromFloat(255.999 * color.x));
    const g = @as(u8, @intFromFloat(255.999 * color.y));
    const b = @as(u8, @intFromFloat(255.999 * color.z));
    try writer.print("{d} {d} {d}\n", .{ r, g, b });
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Set up random number generator
    var prng = std.Random.DefaultPrng.init(420);
    const rng = prng.random();

    const image_width = 800;
    const image_height = 600;

    // anti-aliasing
    const samples_per_pixel = 20;

    const cam = Camera.init(
        Point3.init(0.0, 0.0, 1.0),
        Point3.init(0.0, 0.0, -2.0),
        // 90 degree field of view
        std.math.pi / 2.0,
        @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)),
        0.01,
        2.0,
    );

    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    // initialize allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // add spheres to world
    var world = try World.init(allocator, 4);
    defer world.deinit();
    // Gold sphere
    try world.add_sphere(Sphere.init(Point3.init(0.0, 0.0, -3.0), 1, Material.initMetal(Color.init(0.937, 0.749, 0.016), 0.5)));
    // Pink sphere
    try world.add_sphere(Sphere.init(Point3.init(-1.3, 0.0, -1.5), 0.3, Material.initLambertian(Color.init(1.000, 0.412, 0.706))));
    // Water sphere
    try world.add_sphere(Sphere.init(Point3.init(1.3, 0.0, -1.25), 0.3, Material.initDielectric(1.33)));
    // Glass sphere
    try world.add_sphere(Sphere.init(Point3.init(1.3, 0.5, -2.0), 0.3, Material.initDielectric(1.52)));

    try world.buildBVH();

    var y: u32 = 0;
    while (y < image_height) : (y += 1) {
        var x: u32 = 0;
        while (x < image_width) : (x += 1) {
            // each will be divided by 100 to produce color
            var color = Color.init(0.0, 0.0, 0.0);
            var i: u32 = 0;
            while (i < samples_per_pixel) : (i += 1) {
                const u = (@as(f64, @floatFromInt(x)) + rng.float(f64)) / @as(f64, @floatFromInt(image_width - 1));
                const v = (@as(f64, @floatFromInt(y)) + rng.float(f64)) / @as(f64, @floatFromInt(image_height - 1));
                const pixel_ray = cam.getRay(u, v, rng);
                const sample_color = rayColor(&world, pixel_ray, 0, rng);
                color = color.add(sample_color);
            }
            color = color.mul(1.0 / @as(f64, @floatFromInt(samples_per_pixel)));
            try writeColor(stdout, color);
        }
    }
    try stdout.flush();
}
