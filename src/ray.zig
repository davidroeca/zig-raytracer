const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

pub const Ray = struct {
    origin: Point3,
    direction: Vec3,

    pub fn init(origin: Point3, direction: Vec3) @This() {
        return @This(){
            .origin = origin,
            .direction = direction,
        };
    }

    pub fn at(self: Ray, t: f64) Point3 {
        return self.origin.add(self.direction.mul(t));
    }
};
