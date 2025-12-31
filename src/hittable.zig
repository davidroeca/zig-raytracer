const std = @import("std");
const mat = @import("./material.zig");
const Material = mat.Material;
const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = vec3.Color;
const ray = @import("./ray.zig");
const Ray = ray.Ray;
const aabb = @import("./aabb.zig");
const AABB = aabb.AABB;
const bvh = @import("./bvh.zig");
const BVHNode = bvh.BVHNode;

pub const HitRecord = struct {
    t: f64,
    point: Point3,
    normal: Vec3,
    material: Material,

    pub fn init(t: f64, point: Point3, normal: Vec3, material: Material) @This() {
        return @This(){
            .t = t,
            .point = point,
            .normal = normal,
            .material = material,
        };
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f64,
    material: Material,

    pub fn init(center: Point3, radius: f64, material: Material) @This() {
        return @This(){
            .center = center,
            .radius = radius,
            .material = material,
        };
    }

    pub fn boundingBox(self: @This()) AABB {
        return AABB.init(
            Vec3.init(
                self.center.x - self.radius,
                self.center.y - self.radius,
                self.center.z - self.radius,
            ),
            Vec3.init(
                self.center.x + self.radius,
                self.center.y + self.radius,
                self.center.z + self.radius,
            ),
        );
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
        return HitRecord.init(t, point, normal, self.material);
    }
};

pub const World = struct {
    spheres: std.ArrayList(Sphere),
    bvh_root: ?*BVHNode,
    allocator: std.mem.Allocator,
    bvh_dirty: bool,

    pub fn init(allocator: std.mem.Allocator, capacity: usize) !@This() {
        // initialize spheres
        const spheres = try std.ArrayList(Sphere).initCapacity(allocator, capacity);
        return @This(){
            .spheres = spheres,
            .bvh_root = null,
            .allocator = allocator,
            .bvh_dirty = false,
        };
    }

    pub fn deinit(self: *World) void {
        if (self.bvh_root) |bvh_root| bvh_root.deinit(self.allocator);
        self.spheres.deinit(self.allocator);
    }

    pub fn buildBVH(self: *World) !void {
        self.bvh_root = try BVHNode.build(
            self.spheres.items,
            0,
            self.spheres.items.len,
            self.allocator,
            0,
        );
        self.bvh_dirty = false;
    }

    pub fn ensureBVH(self: *World) !void {
        if (self.bvh_dirty) {
            try self.buildBVH();
        }
    }

    pub fn add_sphere(self: *@This(), sphere: Sphere) !void {
        try self.spheres.append(self.allocator, sphere);
        self.bvh_dirty = true;
    }

    pub fn hit(self: *@This(), ray_: Ray, t_min: f64, t_max: f64) ?HitRecord {
        if (self.bvh_root) |root| {
            return root.hit(ray_, t_min, t_max, self);
        } else {
            // Linear search fallback
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
    }
};
