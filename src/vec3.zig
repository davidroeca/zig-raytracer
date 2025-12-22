const std = @import("std");

pub const Vec3 = struct {
    x: f64,
    y: f64,
    z: f64,

    pub fn init(x: f64, y: f64, z: f64) Vec3 {
        return Vec3{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn format(
        self: Vec3,
        writer: anytype,
    ) !void {
        try writer.print("Vec3({d}, {d}, {d})", .{ self.x, self.y, self.z });
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3.init(self.x + other.x, self.y + other.y, self.z + other.z);
    }

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return Vec3.init(self.x - other.x, self.y - other.y, self.z - other.z);
    }

    pub fn mul(self: Vec3, scalar: f64) Vec3 {
        return Vec3.init(self.x * scalar, self.y * scalar, self.z * scalar);
    }

    pub fn dot(self: Vec3, other: Vec3) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn length(self: Vec3) f64 {
        return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    pub fn unitVector(self: Vec3) Vec3 {
        const magnitude = self.length();
        // Avoid divide by 0. Consider errors instead
        if (magnitude == 0.0) {
            return Vec3.init(0.0, 0.0, 0.0);
        }
        return Vec3.init(self.x / magnitude, self.y / magnitude, self.z / magnitude);
    }
};

pub const Point3 = Vec3;
pub const Color = Vec3;
