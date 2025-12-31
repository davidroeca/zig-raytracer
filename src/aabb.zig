// axis-aligned bounding box
const ray = @import("./ray.zig");
const Ray = ray.Ray;
const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

const ZERO_TOLERANCE = 1e-8;

fn checkAxisBounds(t0: f64, t1: f64, t_min: f64, t_max: f64) bool {
    const entry, const exit = if (t0 <= t1)
        .{ t0, t1 }
    else
        .{ t1, t0 };
    return ((t_min <= entry and entry <= t_max) or
        (t_min <= exit and exit <= t_max));
}

pub const AABB = struct {
    min: Point3,
    max: Point3,

    pub fn init(min: Point3, max: Point3) @This() {
        return @This(){
            .min = min,
            .max = max,
        };
    }

    pub fn hit(self: @This(), ray_: Ray, t_min: f64, t_max: f64) bool {
        if (@abs(ray_.direction.x) < ZERO_TOLERANCE) {
            if (self.min.x > ray_.origin.x or ray_.origin.x > self.max.x) {
                return false;
            }
        } else {
            // confirm that ray passes through x bounds; otherwise return false
            const t0 = (self.min.x - ray_.origin.x) / ray_.direction.x;
            const t1 = (self.max.x - ray_.origin.x) / ray_.direction.x;
            if (!checkAxisBounds(t0, t1, t_min, t_max)) {
                return false;
            }
        }
        if (@abs(ray_.direction.y) < ZERO_TOLERANCE) {
            if (self.min.y > ray_.origin.y or ray_.origin.y > self.max.y) {
                return false;
            }
        } else {
            // confirm that ray passes through x bounds; otherwise return false
            const t0 = (self.min.y - ray_.origin.y) / ray_.direction.y;
            const t1 = (self.max.y - ray_.origin.y) / ray_.direction.y;
            if (!checkAxisBounds(t0, t1, t_min, t_max)) {
                return false;
            }
        }
        if (@abs(ray_.direction.z) < ZERO_TOLERANCE) {
            if (self.min.z > ray_.origin.z or ray_.origin.z > self.max.z) {
                return false;
            }
        } else {
            // confirm that ray passes through x bounds; otherwise return false
            const t0 = (self.min.z - ray_.origin.z) / ray_.direction.z;
            const t1 = (self.max.z - ray_.origin.z) / ray_.direction.z;
            if (!checkAxisBounds(t0, t1, t_min, t_max)) {
                return false;
            }
        }
        return true;
    }

    pub fn surrounding(self: @This(), other: @This()) @This() {
        return @This().init(
            Vec3.init(
                @min(self.min.x, other.min.x),
                @min(self.min.y, other.min.y),
                @min(self.min.z, other.min.z),
            ),
            Vec3.init(
                @max(self.max.x, other.max.x),
                @max(self.max.y, other.max.y),
                @max(self.max.z, other.max.z),
            ),
        );
    }
};
