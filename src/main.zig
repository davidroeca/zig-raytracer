const std = @import("std");
const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = vec3.Color;
const ray = @import("./ray.zig");
const Ray = ray.Ray;

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

fn rayColor(r: Ray) Color {
    // rainbot spiral
    const unit_direction = r.direction.unitVector();
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

    const image_width = 600;
    const image_height = 800;

    const camera_position = Point3.init(0.0, 0.0, 0.0);

    const viewport_height = 2.0;
    const viewport_width = viewport_height * (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));

    const focal_length = 1.0; // distance from cam to location

    const viewport_u = Vec3.init(viewport_width, 0.0, 0.0);
    const viewport_v = Vec3.init(0.0, -viewport_height, 0.0);

    // Vec differences per pixel
    const pixel_delta_u = viewport_u.mul(1.0 / @as(f64, @floatFromInt(image_width)));
    const pixel_delta_v = viewport_v.mul(1.0 / @as(f64, @floatFromInt(image_height)));

    // Find upper right vec
    const viewport_top_left = camera_position
        .sub(Vec3.init(0.0, 0.0, focal_length))
        .sub(viewport_u.mul(0.5))
        .sub(viewport_v.mul(0.5));
    const first_pixel = viewport_top_left.add(pixel_delta_u).add(pixel_delta_v).mul(0.5);

    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    var y: u32 = 0;
    while (y < image_height) : (y += 1) {
        var x: u32 = 0;
        while (x < image_width) : (x += 1) {
            const pixel_center = first_pixel
                .add(pixel_delta_u.mul(@as(f64, @floatFromInt(x))))
                .add(pixel_delta_v.mul(@as(f64, @floatFromInt(y))));
            const ray_direction = pixel_center.sub(camera_position);
            const pixel_ray = Ray.init(camera_position, ray_direction);
            const color = rayColor(pixel_ray);
            try writeColor(stdout, color);
        }
    }
    try stdout.flush();
}
