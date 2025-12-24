const std = @import("std");
const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = vec3.Color;
const ray = @import("./ray.zig");
const Ray = ray.Ray;

pub const HitRecord = struct {
    t: f64,
    point: Point3,
    normal: Vec3,
    color: Color,

    pub fn init(t: f64, point: Point3, normal: Vec3, color: Color) @This() {
        return @This(){
            .t = t,
            .point = point,
            .normal = normal,
            .color = color,
        };
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f64,

    pub fn init(center: Point3, radius: f64) @This() {
        return @This(){
            .center = center,
            .radius = radius,
        };
    }

    pub fn hit(self: @This(), ray_: Ray) ?HitRecord {
        const dir = ray_.direction;
        // intermediate variables to get distance between origin and sphere center
        // used in quadratic variable c
        const origin_to_center = ray_.origin.sub(self.center);
        // --- quadriatic equaiton variables
        const a = dir.dot(dir);
        const b = 2 * dir.dot(ray_.origin.sub(self.center));
        const c = origin_to_center.dot(origin_to_center) - self.radius * self.radius;
        // --- end quadratic equation variables

        const radical_part = b * b - 4.0 * a * c;
        if (radical_part < 0.0) {
            return null;
        }
        const sqrt_rad = std.math.sqrt(radical_part);

        // consider adding the + sqrt_rad solution if allowing hits from
        // within the sphere
        const t = (-b - sqrt_rad) / (2.0 * a);
        if (t < 0.0) {
            return null;
        }
        const point = ray_.origin.add(ray_.direction.mul(t));
        const normal = point.sub(self.center).unitVector();
        // alter domain from [-1, 1] to [0, 1]
        const color = (Color.init(1.0, 1.0, 1.0).add(normal)).mul(0.5);
        return HitRecord.init(t, point, normal, color);
    }
};

pub const World = struct {
    spheres: std.ArrayList(Sphere),
    allocator: std.mem.Allocator,

    pub fn init(spheres: std.ArrayList(Sphere), allocator: std.mem.Allocator) @This() {
        return @This(){
            .spheres = spheres,
            .allocator = allocator,
        };
    }

    pub fn add_sphere(self: *@This(), sphere: Sphere) !void {
        try self.spheres.append(self.allocator, sphere);
    }

    pub fn hit(self: @This(), ray_: Ray) ?HitRecord {
        var result: ?HitRecord = null;
        for (self.spheres.items) |item| {
            const cur_opt_hit = item.hit(ray_);
            if (cur_opt_hit) |cur_hit| {
                if (result == null or result.?.t > cur_hit.t) {
                    result = cur_hit;
                }
            }
        }
        return result;
    }
};
