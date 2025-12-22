const std = @import("std");
const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;

pub fn main() !void {
    const myvec = Vec3.init(7.0, 8.0, 9.0);
    std.debug.print("{f}\n", .{myvec});
}
