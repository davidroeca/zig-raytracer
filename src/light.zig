const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = vec3.Color;

pub const PointLight = struct {
    /// point: point where the light is emitted
    position: Point3,
    /// color: the hue of the light - mathematical domain: [0.0, 1.0]^3
    color: Color,
    /// intensity: non-unit intensity - mathematical domain: (0.0, inf)
    intensity: f64,

    pub fn init(
        position: Point3,
        color: Color,
        intensity: f64,
    ) @This() {
        return @This(){
            .position = position,
            .color = color,
            .intensity = intensity,
        };
    }
};
