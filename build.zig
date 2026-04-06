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

    // WASM target for browser rendering
    const wasm = b.addExecutable(.{
        .name = "raytracer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/wasm_entry.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .wasm32,
                .os_tag = .freestanding,
            }),
            .optimize = .ReleaseFast,
        }),
    });
    wasm.entry = .disabled;
    wasm.rdynamic = true;
    const install_wasm = b.addInstallArtifact(wasm, .{});
    const wasm_step = b.step("wasm", "Build WASM binary for browser");
    wasm_step.dependOn(&install_wasm.step);
}
