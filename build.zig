const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/dec_to_hex.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "dectohex",
        .root_module = mod,
    });

    b.installArtifact(exe);
    const run_step = b.step("dectohex", "convert from hexadecimal to decimal");
    const exe_artifact = b.addRunArtifact(exe);
    if (b.args) |args| {
        exe_artifact.addArgs(args);
    }
    run_step.dependOn(&exe_artifact.step);

    const test_mod = b.addTest(.{
        .root_module = mod,
    });
    const test_step = b.step("test", "test dectohex");
    const test_artifact = b.addRunArtifact(test_mod);
    test_step.dependOn(&test_artifact.step);
}
