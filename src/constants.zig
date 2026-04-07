// Near-zero threshold for floating point comparisons (parallel rays, degenerate vectors)
pub const ZERO_TOLERANCE = 1e-8;

// Small offset to push ray origins away from surfaces, preventing self-intersection
pub const SURFACE_OFFSET = 0.001;
