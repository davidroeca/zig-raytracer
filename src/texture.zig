const std = @import("std");
const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;

pub const Texture = union(enum) {
    solid: struct {
        color: Color,
    },
    checkerboard: struct {
        even: Color,
        odd: Color,
        scale: f64,
    },

    pub fn initSolid(color: Color) @This() {
        return @This(){ .solid = .{ .color = color } };
    }

    pub fn initCheckerboard(even: Color, odd: Color, scale: f64) @This() {
        return @This(){ .checkerboard = .{ .even = even, .odd = odd, .scale = scale } };
    }

    pub fn value(self: @This(), point: Point3) Color {
        switch (self) {
            .solid => |s| return s.color,
            .checkerboard => |cb| {
                // Sum of floored scaled coordinates determines which grid cell we're in
                const sum = @floor(point.x * cb.scale) +
                    @floor(point.y * cb.scale) +
                    @floor(point.z * cb.scale);
                // Even parity = even color, odd parity = odd color
                const parity: i64 = @intFromFloat(sum);
                if (@mod(parity, 2) == 0) {
                    return cb.even;
                } else {
                    return cb.odd;
                }
            },
        }
    }
};
