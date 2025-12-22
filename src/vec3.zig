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

test "Vec3 addition" {
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(4, 5, 6);
    const result = a.add(b);

    try std.testing.expectEqual(5, result.x);
    try std.testing.expectEqual(7, result.y);
    try std.testing.expectEqual(9, result.z);
}

test "Vec3 subtraction" {
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(4, 5, 6);
    const result = a.sub(b);

    try std.testing.expectEqual(-3, result.x);
    try std.testing.expectEqual(-3, result.y);
    try std.testing.expectEqual(-3, result.z);
}

test "Vec3 multiplication" {
    const a = Vec3.init(1, 2, 3);
    const result = a.mul(7);

    try std.testing.expectEqual(7, result.x);
    try std.testing.expectEqual(14, result.y);
    try std.testing.expectEqual(21, result.z);
}

test "Vec3 dot product" {
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(4, 5, 6);
    const result = a.dot(b);

    try std.testing.expectEqual(32, result);
}

test "Vec3 length" {
    const a = Vec3.init(1, 2, 3);
    const result = a.length();
    const tolerance = 0.00001;
    try std.testing.expectApproxEqAbs(3.74165739, result, tolerance);
}

test "Vec3 unit vector" {
    const a = Vec3.init(1, 2, 3);
    const result = a.unitVector();
    const tolerance = 0.00001;
    try std.testing.expectApproxEqAbs(0.26726124, result.x, tolerance);
    try std.testing.expectApproxEqAbs(0.53452248, result.y, tolerance);
    try std.testing.expectApproxEqAbs(0.80178373, result.z, tolerance);
}

pub const Point3 = Vec3;
pub const Color = Vec3;
