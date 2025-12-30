const std = @import("std");
const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const ray = @import("./ray.zig");
const Ray = ray.Ray;

fn randomInUnitDisk(rng: std.Random) Vec3 {
    // Just return a unit vector projected onto the xy plane
    const randVec = vec3.randomUnitVector(rng);
    return randVec.add(Vec3.init(0.0, 0.0, -randVec.z)).unitVector();
}

pub const Camera = struct {
    origin: Point3,
    horizontal: Vec3,
    vertical: Vec3,
    u: Vec3,
    v: Vec3,
    lower_left_corner: Vec3,
    lens_radius: f64,

    pub fn init(
        position: Point3,
        look_at: Point3,
        vfov: f64,
        aspect_ratio: f64,
        aperture: f64,
        focus_distance: f64,
    ) @This() {
        const focal_length = 1.0;
        const vh = 2.0 * focal_length * @tan(vfov / 2.0);
        const vw = vh * aspect_ratio;
        const world_up = Vec3.init(0.0, 1.0, 0.0);
        const w = position.sub(look_at).unitVector();
        // World up is y so we do a cross product with that vector to get the right vector
        const use_fallback = w.cross(world_up).length() < 0.001;
        const reference = if (use_fallback)
            Vec3.init(0.0, 0.0, 1.0) // Edge case - use forward/backward as reference instead
        else
            world_up;
        const u = reference.cross(w).unitVector();
        const v = u.cross(w).unitVector();
        const horizontal = u.mul(vw * focus_distance);
        const vertical = v.mul(vh * focus_distance);
        const lower_left_corner = position
            .sub(w.mul(focus_distance))
            .sub(vertical.mul(0.5))
            .sub(horizontal.mul(0.5));
        return @This(){
            .origin = position,
            .horizontal = horizontal,
            .vertical = vertical,
            .u = u,
            .v = v,
            .lower_left_corner = lower_left_corner,
            .lens_radius = aperture / 2.0,
        };
    }

    pub fn getRay(self: @This(), u: f64, v: f64, rng: std.Random) Ray {
        const rd = randomInUnitDisk(rng).mul(self.lens_radius);
        const random_offset = self.u.mul(rd.x).add(self.v.mul(rd.y));
        const ray_origin = self.origin.add(random_offset);
        const ray_direction = self.lower_left_corner
            .add(self.horizontal.mul(u))
            .add(self.vertical.mul(v))
            .sub(ray_origin);
        return Ray.init(ray_origin, ray_direction);
    }
};
