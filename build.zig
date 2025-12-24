const std = @import("std");

pub fn build(b: *std.Build) void {
    const main_exe = b.addExecutable(.{
        .name = "main",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
        }),
    });
    b.installArtifact(main_exe);
    const run_main = b.addRunArtifact(main_exe);
    const run_main_step = b.step("main", "Run main binary");
    run_main_step.dependOn(&run_main.step);
}
