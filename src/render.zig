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
const Plane = hittable.Plane;
const Box = hittable.Box;
const Quad = hittable.Quad;
const Disk = hittable.Disk;
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;
pub const World = hittable.World;
const tex = @import("./texture.zig");
const Texture = tex.Texture;
const light = @import("./light.zig");
const PointLight = light.PointLight;
const constants = @import("./constants.zig");

const MAX_RAY_DEPTH: u8 = 50;
const SKY_INTENSITY: f64 = 0.15;

fn directLighting(world: *World, hit: HitRecord, albedo: Color) Color {
    var total = Color.init(0.0, 0.0, 0.0);
    for (world.lights.items) |light_| {
        const to_light = light_.position.sub(hit.point);
        const dist2 = to_light.dot(to_light);
        const dist = @sqrt(dist2);
        const L = to_light.mul(1.0 / dist);
        const n_dot_l = hit.normal.dot(L);
        if (n_dot_l <= 0.0) continue; // light is behind surface
        // Shadow ray: offset origin to avoid self-intersection
        const shadow_origin = hit.point.add(hit.normal.mul(constants.SURFACE_OFFSET));
        const shadow_ray = Ray.init(shadow_origin, L);
        // t_max = dist (in the L direction)
        if (world.hit(shadow_ray, 0.001, dist)) |_| {
            continue; // occluded
        }

        const light_emission = light_.color.mul(light_.intensity);
        const contribution = albedo.mulVec(light_emission).mul(n_dot_l / dist2);
        total = total.add(contribution);
    }
    return total;
}

fn rayColor(world: *World, ray_: Ray, depth: u8, rng: std.Random) Color {
    const t_min = 0.001;
    const t_max = std.math.inf(f64);
    if (depth > MAX_RAY_DEPTH) {
        return Color.init(0.0, 0.0, 0.0);
    }
    const opt_hit = world.hit(ray_, t_min, t_max);
    if (opt_hit) |hit| {
        // Direct lighting term - for lambertian surfaces
        var direct = Color.init(0.0, 0.0, 0.0);
        if (hit.material == .lambertian) {
            const albedo = hit.material.lambertian.albedo.value(hit.point);
            direct = directLighting(world, hit, albedo);
        }
        if (hit.material.scatter(ray_, hit, rng)) |scatter| {
            const incoming_color = rayColor(
                world,
                scatter.scattered,
                depth + 1,
                rng,
            );
            return direct.add(incoming_color.mulVec(scatter.attenuation));
        }
        return direct;
    }
    // Sky gradient: warm white at horizon, deeper blue at zenith
    const unit_direction = ray_.direction.unitVector();
    const t = 0.5 * (unit_direction.y + 1.0);
    const horizon = Color.init(1.0, 0.95, 0.85);
    const zenith = Color.init(0.3, 0.5, 0.9);
    const warm_sky = horizon.mul(1.0 - t).add(zenith.mul(t));

    // Convert warm sky to dark sky
    return warm_sky.mul(SKY_INTENSITY);
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
        // 50 degree field of view
        std.math.pi / 3.6,
        @as(f64, @floatFromInt(config.image_width)) / @as(f64, @floatFromInt(config.image_height)),
        0.02,
        4.0,
    );
}

pub fn setupWorld(allocator: std.mem.Allocator) !World {
    const objects = &.{
        // Ground plane with checkerboard texture
        Hittable{ .plane = Plane.init(
            Point3.init(0.0, -1.5, 0.0),
            Vec3.init(0.0, 1.0, 0.0),
            Material.initLambertianTextured(Texture.initCheckerboard(
                Color.init(0.9, 0.9, 0.9),
                Color.init(0.2, 0.2, 0.2),
                1.0,
            )),
        ) },

        // Center: large polished metal sphere (silver)
        Hittable{ .sphere = Sphere.init(Point3.init(0.0, 0.0, -3.0), 0.5, Material.initMetal(Color.init(0.8, 0.8, 0.85), 0.02)) },
        // Glass sphere sitting on top of the metal sphere
        Hittable{ .sphere = Sphere.init(Point3.init(0.0, 0.85, -3.0), 0.35, Material.initDielectric(1.5)) },

        // Left: matte terracotta sphere
        Hittable{ .sphere = Sphere.init(Point3.init(-1.0, 0.0, -1.5), 0.5, Material.initLambertian(Color.init(0.8, 0.35, 0.2))) },

        // Right: gold metal sphere
        Hittable{ .sphere = Sphere.init(Point3.init(1.3, 0.0, -1.5), 0.5, Material.initMetal(Color.init(0.85, 0.65, 0.1), 0.1)) },

        // Far back: large matte blue sphere
        Hittable{ .sphere = Sphere.init(Point3.init(-1.5, 0.3, -4.0), 0.8, Material.initLambertian(Color.init(0.15, 0.2, 0.55))) },

        // Small glass marble, front-left
        Hittable{ .sphere = Sphere.init(Point3.init(-0.5, -0.3, -0.8), 0.3, Material.initDielectric(1.5)) },

        // Small polished copper sphere, front-right
        Hittable{ .sphere = Sphere.init(Point3.init(0.7, -0.3, -0.7), 0.2, Material.initMetal(Color.init(0.9, 0.5, 0.3), 0.0)) },

        // Axis-aligned box (pedestal)
        Hittable{ .box = Box.init(
            Point3.init(-0.2, -1.6, -2.8),
            Point3.init(0.4, -1.0, -2.2),
            Material.initLambertian(Color.init(0.0, 1.0, 0.3)),
        ) },

        // Disk resting on the box
        Hittable{ .disk = Disk.init(
            Point3.init(0.1, -0.99, -2.5),
            Vec3.init(0.0, 1.0, 0.0),
            0.25,
            Material.initMetal(Color.init(0.9, 0.75, 0.2), 0.05),
        ) },

        // Wall quad in the back
        Hittable{ .quad = Quad.init(
            Point3.init(-3.0, -0.5, -5.0),
            Vec3.init(6.0, 0.0, 0.0),
            Vec3.init(0.0, 4.0, 0.0),
            Material.initLambertian(Color.init(0.7, 0.7, 0.75)),
        ) },
    };

    const lights = &.{
        PointLight.init(
            Point3.init(1.8, 2.0, -1.5),
            Color.init(1.0, 0.95, 0.85),
            8.0,
        ),
        PointLight.init(
            Point3.init(-2.5, 1.2, -0.0),
            Color.init(0.6, 0.7, 1.0),
            4.0,
        ),
    };

    const num_lights = lights.len;
    // Requires calc - could be good to restructure data to make this simpler
    var num_unbounded: usize = 0;
    inline for (objects) |object| {
        if (object.boundingBox() == null) {
            num_unbounded += 1;
        }
    }
    const num_bounded = objects.len - num_unbounded;

    var world = try World.init(
        allocator,
        num_bounded,
        num_unbounded,
        num_lights,
    );
    errdefer world.deinit();

    inline for (objects) |object| {
        try world.addObject(object);
    }

    inline for (lights) |light_| {
        try world.addLight(light_);
    }

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
            buffer[offset] = @intFromFloat(255.999 * std.math.clamp(color.x, 0.0, 1.0));
            buffer[offset + 1] = @intFromFloat(255.999 * std.math.clamp(color.y, 0.0, 1.0));
            buffer[offset + 2] = @intFromFloat(255.999 * std.math.clamp(color.z, 0.0, 1.0));
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
