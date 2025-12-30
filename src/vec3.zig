const std = @import("std");

pub const Vec3 = struct {
    x: f64,
    y: f64,
    z: f64,

    pub fn init(x: f64, y: f64, z: f64) @This() {
        return @This(){
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn format(
        self: @This(),
        writer: anytype,
    ) !void {
        try writer.print("{s}({d}, {d}, {d})", .{ @typeName(@This()), self.x, self.y, self.z });
    }

    pub fn add(self: @This(), other: @This()) @This() {
        return @This().init(self.x + other.x, self.y + other.y, self.z + other.z);
    }

    pub fn sub(self: @This(), other: @This()) @This() {
        return @This().init(self.x - other.x, self.y - other.y, self.z - other.z);
    }

    pub fn mul(self: @This(), scalar: f64) @This() {
        return @This().init(self.x * scalar, self.y * scalar, self.z * scalar);
    }

    pub fn dot(self: @This(), other: @This()) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn length(self: @This()) f64 {
        return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    pub fn unitVector(self: @This()) @This() {
        const magnitude = self.length();
        // Avoid divide by 0. Consider errors instead
        if (magnitude == 0.0) {
            return @This().init(0.0, 0.0, 0.0);
        }
        return @This().init(self.x / magnitude, self.y / magnitude, self.z / magnitude);
    }
};

pub fn randomUnitVector(rng: std.Random) Vec3 {
    return Vec3.init(rng.float(f64), rng.float(f64), rng.float(f64)).unitVector();
}

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

test "randomUnitVector" {
    const prng = std.Random.DefaultPrng;
    const rand = prng.random();
    const my_unit = randomUnitVector(rand);
    const my_unit2 = randomUnitVector(rand);
    const tolerance = 0.00001;
    try std.testing.expectApproxEqAbs(1.0, my_unit.length(), tolerance);
    try std.testing.expectApproxEqAbs(1.0, my_unit2.length(), tolerance);
}

pub const Point3 = Vec3;
pub const Color = Vec3;
