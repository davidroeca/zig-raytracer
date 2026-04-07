// axis-aligned bounding box
const ray = @import("./ray.zig");
const Ray = ray.Ray;
const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

const constants = @import("./constants.zig");

pub const AABB = struct {
    min: Point3,
    max: Point3,

    pub fn init(min: Point3, max: Point3) @This() {
        return @This(){
            .min = min,
            .max = max,
        };
    }

    // Standard slab method: accumulate the intersection of all axis intervals
    pub fn hit(self: @This(), ray_: Ray, t_min: f64, t_max: f64) bool {
        const mins = [3]f64{ self.min.x, self.min.y, self.min.z };
        const maxs = [3]f64{ self.max.x, self.max.y, self.max.z };
        const origins = [3]f64{ ray_.origin.x, ray_.origin.y, ray_.origin.z };
        const dirs = [3]f64{ ray_.direction.x, ray_.direction.y, ray_.direction.z };

        var t_near = t_min;
        var t_far = t_max;

        for (0..3) |axis| {
            if (@abs(dirs[axis]) < constants.ZERO_TOLERANCE) {
                // Ray parallel to slab; miss if origin not within slab
                if (origins[axis] < mins[axis] or origins[axis] > maxs[axis]) {
                    return false;
                }
            } else {
                const inv_d = 1.0 / dirs[axis];
                var t0 = (mins[axis] - origins[axis]) * inv_d;
                var t1 = (maxs[axis] - origins[axis]) * inv_d;
                if (t0 > t1) {
                    const tmp = t0;
                    t0 = t1;
                    t1 = tmp;
                }
                t_near = @max(t_near, t0);
                t_far = @min(t_far, t1);
                if (t_near > t_far) return false;
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
