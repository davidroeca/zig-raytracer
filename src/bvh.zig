// Bounding Volume Hierarchy
const std = @import("std");
const aabb = @import("./aabb.zig");
const AABB = aabb.AABB;
const ray = @import("./ray.zig");
const Ray = ray.Ray;
const hittable = @import("./hittable.zig");
const HitRecord = hittable.HitRecord;
const World = hittable.World;
const Sphere = hittable.Sphere;

fn compareX(_: void, a: Sphere, b: Sphere) bool {
    return a.boundingBox().min.x < b.boundingBox().min.x;
}

fn compareY(_: void, a: Sphere, b: Sphere) bool {
    return a.boundingBox().min.y < b.boundingBox().min.y;
}

fn compareZ(_: void, a: Sphere, b: Sphere) bool {
    return a.boundingBox().min.z < b.boundingBox().min.z;
}

pub const BVHNode = struct {
    bbox: AABB,
    left: ?*@This(),
    right: ?*@This(),
    object_index: ?usize,

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        if (self.left) |left| left.deinit(allocator);
        if (self.right) |right| right.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn hit(self: *@This(), ray_: Ray, t_min: f64, t_max: f64, world: *World) ?HitRecord {
        if (!self.*.bbox.hit(ray_, t_min, t_max)) {
            return null;
        }
        // If object index is set, this is a leaf
        if (self.*.object_index) |object_index| {
            // Handle case if spheres ever get removed
            if (object_index >= world.*.spheres.items.len) {
                return null;
            }
            return world.*.spheres.items[object_index].hit(ray_);
        }
        if (self.*.left) |left| {
            if (left.*.hit(ray_, t_min, t_max, world)) |hit_record| {
                return hit_record;
            }
        }
        if (self.*.right) |right| {
            if (right.*.hit(ray_, t_min, t_max, world)) |hit_record| {
                return hit_record;
            }
        }
        return null;
    }

    pub fn build(
        objects: []Sphere,
        start: usize,
        end: usize,
        allocator: std.mem.Allocator,
        depth: usize,
    ) !?*@This() {
        if (start >= end) {
            return null;
        }
        const num_objects = end - start;
        if (num_objects == 1) {
            std.debug.print("start = {d}, end = {d}\n", .{ start, end });
            const node = try allocator.create(@This());
            node.* = @This(){
                .bbox = objects[start].boundingBox(),
                .left = null,
                .right = null,
                .object_index = start,
            };
            return node;
        } else if (num_objects == 2) {
            const left = try allocator.create(@This());
            left.* = @This(){
                .bbox = objects[start].boundingBox(),
                .left = null,
                .right = null,
                .object_index = start,
            };
            const right = try allocator.create(@This());
            right.* = @This(){
                .bbox = objects[start + 1].boundingBox(),
                .left = null,
                .right = null,
                .object_index = start + 1,
            };
            const node = try allocator.create(@This());
            node.* = @This(){
                .bbox = left.*.bbox.surrounding(right.*.bbox),
                .left = left,
                .right = right,
                .object_index = null,
            };
            return node;
        }
        // create sub-trees
        // cycle through axes per level of depth in tree
        const axis = @mod(depth, 3);
        // sort along axis
        switch (axis) {
            0 => std.mem.sort(
                Sphere,
                objects[start..end],
                {},
                compareX,
            ),
            1 => std.mem.sort(
                Sphere,
                objects[start..end],
                {},
                compareY,
            ),
            2 => std.mem.sort(
                Sphere,
                objects[start..end],
                {},
                compareZ,
            ),
            else => unreachable,
        }
        const right_start = start + num_objects / 2;
        const left = try @This().build(
            objects,
            start,
            right_start,
            allocator,
            depth + 1,
        );
        const right = try @This().build(
            objects,
            right_start,
            end,
            allocator,
            depth + 1,
        );
        const node = try allocator.create(@This());
        node.* = @This(){
            .bbox = left.?.*.bbox.surrounding(right.?.*.bbox),
            .left = left,
            .right = right,
            .object_index = null,
        };
        return node;
    }
};
