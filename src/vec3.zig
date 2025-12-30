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
        return @This().init(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
        );
    }

    pub fn sub(self: @This(), other: @This()) @This() {
        return @This().init(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
        );
    }

    pub fn mul(self: @This(), scalar: f64) @This() {
        return @This().init(self.x * scalar, self.y * scalar, self.z * scalar);
    }

    pub fn dot(self: @This(), other: @This()) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn cross(self: @This(), other: @This()) @This() {
        return @This().init(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x,
        );
    }

    pub fn mulVec(self: @This(), other: @This()) @This() {
        return @This().init(
            self.x * other.x,
            self.y * other.y,
            self.z * other.z,
        );
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

    pub fn reflect(self: @This(), normal: @This()) @This() {
        const normal_component_magnitude = self.dot(normal);
        // Confirm that normal is length 1
        const normal_length = normal.length();
        // Take normal component magnitude and reverse it
        return self.add(normal.mul(-2 * normal_component_magnitude / normal_length));
    }
};

pub fn randomUnitVector(rng: std.Random) Vec3 {
    while (true) {
        // numbers in [-1, 1]
        const x = rng.float(f64) * 2.0 - 1.0;
        const y = rng.float(f64) * 2.0 - 1.0;
        const z = rng.float(f64) * 2.0 - 1.0;
        const candidate = Vec3.init(x, y, z);
        const length_squared = candidate.dot(candidate);
        // Ensures good precision and within unit sphere for proper sampling
        if (length_squared <= 1.0 and length_squared > 0.0001) {
            return candidate.unitVector();
        }
    }
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

test "Vec3 cross product" {
    const a = Vec3.init(2, 3, 4);
    const b = Vec3.init(5, 6, 7);
    const result = a.cross(b);

    try std.testing.expectEqual(-3, result.x);
    try std.testing.expectEqual(6, result.y);
    try std.testing.expectEqual(-3, result.z);
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
    var prng = std.Random.DefaultPrng.init(420);
    const rng = prng.random();
    const my_unit = randomUnitVector(rng);
    const my_unit2 = randomUnitVector(rng);
    const tolerance = 0.00001;
    try std.testing.expectApproxEqAbs(1.0, my_unit.length(), tolerance);
    try std.testing.expectApproxEqAbs(1.0, my_unit2.length(), tolerance);
}

pub const Point3 = Vec3;
pub const Color = Vec3;
