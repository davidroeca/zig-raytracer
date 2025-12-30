const std = @import("std");

const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const hittable = @import("./hittable.zig");
const HitRecord = hittable.HitRecord;
const ray = @import("./ray.zig");
const Ray = ray.Ray;

// Consider alternatives to this approach
const OUTSIDE_REFRACTION_INDEX = 1.0;

pub const Scatter = struct {
    attenuation: Color,
    scattered: Ray,

    pub fn init(attenuation: Color, scattered: Ray) @This() {
        return @This(){
            .attenuation = attenuation,
            .scattered = scattered,
        };
    }
};

pub const Material = union(enum) {
    lambertian: struct {
        albedo: Color,
    },
    metal: struct {
        albedo: Color,
        fuzz: f64,
    },
    dielectric: struct {
        refraction_index: f64,
    },

    pub fn initAmbertian(albedo: Color) @This() {
        return @This(){ .lambertian = .{ .albedo = albedo } };
    }

    pub fn initMetal(albedo: Color, fuzz: f64) @This() {
        return @This(){ .metal = .{ .albedo = albedo, .fuzz = fuzz } };
    }

    pub fn initDielectric(refraction_index: f64) @This() {
        return @This(){ .dielectric = .{ .refraction_index = refraction_index } };
    }

    pub fn scatter(self: @This(), ray_in: Ray, hit: HitRecord, rng: std.Random) ?Scatter {
        switch (self) {
            .lambertian => |lamb| {
                const new_ray_vec = hit.normal.add(vec3.randomUnitVector(rng));
                const new_ray_origin = hit.point.add(hit.normal.mul(0.001));
                const scattered = Ray.init(new_ray_origin, new_ray_vec);
                return Scatter.init(lamb.albedo, scattered);
            },
            .metal => |met| {
                const reflected = ray_in.direction.reflect(hit.normal);
                const fuzzed = reflected.add(vec3.randomUnitVector(rng).mul(met.fuzz));
                if (fuzzed.dot(hit.normal) <= 0) {
                    // reflection goes inward - ray absorbed
                    return null;
                }
                const new_ray_origin = hit.point.add(hit.normal.mul(0.001));
                const scattered = Ray.init(new_ray_origin, fuzzed);
                return Scatter.init(met.albedo, scattered);
            },
            .dielectric => |diel| {
                const ray_normal_dot = ray_in.direction.dot(hit.normal);
                // we're entering material
                if (ray_normal_dot <= 0) {
                    const r = OUTSIDE_REFRACTION_INDEX / diel.refraction_index;
                    const c = -ray_normal_dot;
                    const radical_part = (1.0 - r * r * (1 - c * c));
                    // reflect
                    if (radical_part < 0.0) {
                        const new_ray_vec = ray_in.direction.add(hit.normal.mul(2.0 * c));
                        const new_ray_origin = hit.point.add(hit.normal.mul(0.001));
                        const scattered = Ray.init(new_ray_origin, new_ray_vec);
                        return Scatter.init(Color.init(1.0, 1.0, 1.0), scattered);
                    } else { // refract
                        const new_ray_vec = ray_in.direction.mul(r).add(hit.normal.mul(r * c - std.math.sqrt(radical_part)));
                        const new_ray_origin = hit.point.add(hit.normal.mul(-0.001));
                        const scattered = Ray.init(new_ray_origin, new_ray_vec);
                        return Scatter.init(Color.init(1.0, 1.0, 1.0), scattered);
                    }
                } else { // we're exiting material
                    const r = diel.refraction_index / OUTSIDE_REFRACTION_INDEX;
                    // Flip c in this environment
                    const c = ray_normal_dot;
                    const radical_part = (1.0 - r * r * (1 - c * c));
                    // reflect
                    if (radical_part < 0.0) {
                        const new_ray_vec = ray_in.direction.add(hit.normal.mul(2.0 * c));
                        const new_ray_origin = hit.point.add(hit.normal.mul(-0.001));
                        const scattered = Ray.init(new_ray_origin, new_ray_vec);
                        return Scatter.init(Color.init(1.0, 1.0, 1.0), scattered);
                    } else { // refract
                        const new_ray_vec = ray_in.direction.mul(r).add(hit.normal.mul(r * c - std.math.sqrt(radical_part)));
                        const new_ray_origin = hit.point.add(hit.normal.mul(0.001));
                        const scattered = Ray.init(new_ray_origin, new_ray_vec);
                        return Scatter.init(Color.init(1.0, 1.0, 1.0), scattered);
                    }
                }
            },
        }
    }
};
