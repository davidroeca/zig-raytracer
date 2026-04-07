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
const light = @import("./light.zig");
const PointLight = light.PointLight;

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

const constants = @import("./constants.zig");

pub const Plane = struct {
    point: Point3,
    normal: Vec3,
    material: Material,

    pub fn init(point: Point3, normal: Vec3, material: Material) @This() {
        return @This(){
            .point = point,
            .normal = normal.unitVector(),
            .material = material,
        };
    }

    pub fn hit(self: @This(), ray_: Ray) ?HitRecord {
        const denom = ray_.direction.dot(self.normal);
        if (@abs(denom) < constants.ZERO_TOLERANCE) return null;
        const t = self.point.sub(ray_.origin).dot(self.normal) / denom;
        if (t < 0.0) return null;
        const point = ray_.origin.add(ray_.direction.mul(t));
        // Flip normal to face the incoming ray
        const normal = if (denom < 0.0) self.normal else self.normal.mul(-1.0);
        return HitRecord.init(t, point, normal, self.material);
    }
};

pub const Box = struct {
    min: Point3,
    max: Point3,
    material: Material,

    pub fn init(min: Point3, max: Point3, material: Material) @This() {
        return @This(){
            .min = min,
            .max = max,
            .material = material,
        };
    }

    pub fn boundingBox(self: @This()) AABB {
        return AABB.init(self.min, self.max);
    }

    pub fn hit(self: @This(), ray_: Ray) ?HitRecord {
        const mins = [3]f64{ self.min.x, self.min.y, self.min.z };
        const maxs = [3]f64{ self.max.x, self.max.y, self.max.z };
        const origins = [3]f64{ ray_.origin.x, ray_.origin.y, ray_.origin.z };
        const dirs = [3]f64{ ray_.direction.x, ray_.direction.y, ray_.direction.z };

        var t_entry: f64 = -std.math.inf(f64);
        var t_exit: f64 = std.math.inf(f64);
        var entry_axis: usize = 0;
        var entry_sign: f64 = -1.0;

        for (0..3) |axis| {
            if (@abs(dirs[axis]) < constants.ZERO_TOLERANCE) {
                // Ray parallel to slab; miss if origin not within slab
                if (origins[axis] < mins[axis] or origins[axis] > maxs[axis]) {
                    return null;
                }
            } else {
                const inv_d = 1.0 / dirs[axis];
                var t0 = (mins[axis] - origins[axis]) * inv_d;
                var t1 = (maxs[axis] - origins[axis]) * inv_d;
                var sign: f64 = -1.0;
                if (t0 > t1) {
                    const tmp = t0;
                    t0 = t1;
                    t1 = tmp;
                    sign = 1.0;
                }
                if (t0 > t_entry) {
                    t_entry = t0;
                    entry_axis = axis;
                    entry_sign = sign;
                }
                if (t1 < t_exit) {
                    t_exit = t1;
                }
                if (t_entry > t_exit) return null;
            }
        }

        if (t_entry < 0.0) return null;

        const point = ray_.origin.add(ray_.direction.mul(t_entry));
        // Normal points outward from the entry face
        var normal = Vec3.init(0.0, 0.0, 0.0);
        switch (entry_axis) {
            0 => normal = Vec3.init(entry_sign, 0.0, 0.0),
            1 => normal = Vec3.init(0.0, entry_sign, 0.0),
            2 => normal = Vec3.init(0.0, 0.0, entry_sign),
            else => unreachable,
        }
        return HitRecord.init(t_entry, point, normal, self.material);
    }
};

pub const Quad = struct {
    corner: Point3,
    u_edge: Vec3,
    v_edge: Vec3,
    normal: Vec3,
    material: Material,

    pub fn init(corner: Point3, u_edge: Vec3, v_edge: Vec3, material: Material) @This() {
        return @This(){
            .corner = corner,
            .u_edge = u_edge,
            .v_edge = v_edge,
            .normal = u_edge.cross(v_edge).unitVector(),
            .material = material,
        };
    }

    pub fn boundingBox(self: @This()) AABB {
        const c0 = self.corner;
        const c1 = self.corner.add(self.u_edge);
        const c2 = self.corner.add(self.v_edge);
        const c3 = self.corner.add(self.u_edge).add(self.v_edge);
        const pad = Vec3.init(constants.ZERO_TOLERANCE, constants.ZERO_TOLERANCE, constants.ZERO_TOLERANCE);
        return AABB.init(
            Vec3.init(
                @min(@min(c0.x, c1.x), @min(c2.x, c3.x)),
                @min(@min(c0.y, c1.y), @min(c2.y, c3.y)),
                @min(@min(c0.z, c1.z), @min(c2.z, c3.z)),
            ).sub(pad),
            Vec3.init(
                @max(@max(c0.x, c1.x), @max(c2.x, c3.x)),
                @max(@max(c0.y, c1.y), @max(c2.y, c3.y)),
                @max(@max(c0.z, c1.z), @max(c2.z, c3.z)),
            ).add(pad),
        );
    }

    pub fn hit(self: @This(), ray_: Ray) ?HitRecord {
        const denom = ray_.direction.dot(self.normal);
        if (@abs(denom) < constants.ZERO_TOLERANCE) return null;
        const t = self.corner.sub(ray_.origin).dot(self.normal) / denom;
        if (t < 0.0) return null;

        const point = ray_.origin.add(ray_.direction.mul(t));
        const p = point.sub(self.corner);

        // Project onto u/v edges to get parametric coordinates
        const u_dot_u = self.u_edge.dot(self.u_edge);
        const v_dot_v = self.v_edge.dot(self.v_edge);
        const u_dot_v = self.u_edge.dot(self.v_edge);
        const p_dot_u = p.dot(self.u_edge);
        const p_dot_v = p.dot(self.v_edge);

        const inv_denom = 1.0 / (u_dot_u * v_dot_v - u_dot_v * u_dot_v);
        const alpha = (v_dot_v * p_dot_u - u_dot_v * p_dot_v) * inv_denom;
        const beta = (u_dot_u * p_dot_v - u_dot_v * p_dot_u) * inv_denom;

        if (alpha < 0.0 or alpha > 1.0 or beta < 0.0 or beta > 1.0) return null;

        const normal = if (denom < 0.0) self.normal else self.normal.mul(-1.0);
        return HitRecord.init(t, point, normal, self.material);
    }
};

pub const Disk = struct {
    center: Point3,
    normal: Vec3,
    radius: f64,
    material: Material,

    pub fn init(center: Point3, normal: Vec3, radius: f64, material: Material) @This() {
        return @This(){
            .center = center,
            .normal = normal.unitVector(),
            .radius = radius,
            .material = material,
        };
    }

    pub fn boundingBox(self: @This()) AABB {
        // Tight AABB: for each axis, the extent is radius * sin(angle from normal)
        const nx = self.normal.x;
        const ny = self.normal.y;
        const nz = self.normal.z;
        const dx = self.radius * @sqrt(1.0 - nx * nx);
        const dy = self.radius * @sqrt(1.0 - ny * ny);
        const dz = self.radius * @sqrt(1.0 - nz * nz);
        return AABB.init(
            Vec3.init(self.center.x - dx, self.center.y - dy, self.center.z - dz),
            Vec3.init(self.center.x + dx, self.center.y + dy, self.center.z + dz),
        );
    }

    pub fn hit(self: @This(), ray_: Ray) ?HitRecord {
        const denom = ray_.direction.dot(self.normal);
        if (@abs(denom) < constants.ZERO_TOLERANCE) return null;
        const t = self.center.sub(ray_.origin).dot(self.normal) / denom;
        if (t < 0.0) return null;

        const point = ray_.origin.add(ray_.direction.mul(t));
        const offset = point.sub(self.center);
        if (offset.dot(offset) > self.radius * self.radius) return null;

        const normal = if (denom < 0.0) self.normal else self.normal.mul(-1.0);
        return HitRecord.init(t, point, normal, self.material);
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,
    plane: Plane,
    box: Box,
    quad: Quad,
    disk: Disk,

    pub fn hit(self: @This(), ray_: Ray) ?HitRecord {
        switch (self) {
            .sphere => |s| return s.hit(ray_),
            .plane => |p| return p.hit(ray_),
            .box => |b| return b.hit(ray_),
            .quad => |q| return q.hit(ray_),
            .disk => |d| return d.hit(ray_),
        }
    }

    pub fn boundingBox(self: @This()) ?AABB {
        switch (self) {
            .sphere => |s| return s.boundingBox(),
            .plane => return null,
            .box => |b| return b.boundingBox(),
            .quad => |q| return q.boundingBox(),
            .disk => |d| return d.boundingBox(),
        }
    }
};

pub const World = struct {
    objects: std.ArrayList(Hittable),
    unbounded: std.ArrayList(Hittable),
    lights: std.ArrayList(PointLight),
    bvh_root: ?*BVHNode,
    allocator: std.mem.Allocator,
    bvh_dirty: bool,

    pub fn init(
        allocator: std.mem.Allocator,
        object_capacity: usize,
        unbounded_capacity: usize,
        light_capacity: usize,
    ) !@This() {
        var objects = try std.ArrayList(Hittable).initCapacity(allocator, object_capacity);
        errdefer objects.deinit(allocator);
        var unbounded = try std.ArrayList(Hittable).initCapacity(allocator, unbounded_capacity);
        errdefer unbounded.deinit(allocator);
        var lights = try std.ArrayList(PointLight).initCapacity(allocator, light_capacity);
        errdefer lights.deinit(allocator);
        return @This(){
            .objects = objects,
            .unbounded = unbounded,
            .lights = lights,
            .bvh_root = null,
            .allocator = allocator,
            .bvh_dirty = false,
        };
    }

    pub fn deinit(self: *World) void {
        if (self.bvh_root) |bvh_root| bvh_root.deinit(self.allocator);
        self.objects.deinit(self.allocator);
        self.unbounded.deinit(self.allocator);
    }

    pub fn buildBVH(self: *World) !void {
        self.bvh_root = try BVHNode.build(
            self.objects.items,
            0,
            self.objects.items.len,
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

    pub fn addLight(self: *@This(), light_: PointLight) !void {
        try self.lights.append(self.allocator, light_);
    }

    pub fn addObject(self: *@This(), object: Hittable) !void {
        if (object.boundingBox() != null) {
            try self.objects.append(self.allocator, object);
        } else {
            try self.unbounded.append(self.allocator, object);
        }
        self.bvh_dirty = true;
    }

    pub fn hit(self: *@This(), ray_: Ray, t_min: f64, t_max: f64) ?HitRecord {
        var result: ?HitRecord = null;

        // Test bounded objects via BVH
        if (self.bvh_root) |root| {
            result = root.hit(ray_, t_min, t_max, self);
        } else {
            for (self.objects.items) |item| {
                const cur_opt_hit = item.hit(ray_);
                if (cur_opt_hit) |cur_hit| {
                    if (cur_hit.t >= t_min and cur_hit.t <= t_max) {
                        if (result == null or result.?.t > cur_hit.t) {
                            result = cur_hit;
                        }
                    }
                }
            }
        }

        // Linear scan of unbounded objects
        for (self.unbounded.items) |item| {
            const cur_opt_hit = item.hit(ray_);
            if (cur_opt_hit) |cur_hit| {
                if (cur_hit.t >= t_min and cur_hit.t <= t_max) {
                    if (result == null or result.?.t > cur_hit.t) {
                        result = cur_hit;
                    }
                }
            }
        }

        return result;
    }
};
