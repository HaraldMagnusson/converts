const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ExecutableSource = struct {
        path: []const u8,
        name: []const u8,
        description: []const u8,
    };
    const executables = comptime [_]ExecutableSource{
        .{
            .path = "src/dec_to_hex.zig",
            .name = "dectohex",
            .description = "convert from decimal to hexadecimal",
        },
        .{
            .path = "src/hex_to_dec.zig",
            .name = "hextodec",
            .description = "convert from hexadecimal to decimal",
        },
    };

    inline for (executables) |executable| {
        const mod = b.createModule(.{
            .root_source_file = b.path(executable.path),
            .target = target,
            .optimize = optimize,
        });

        const exe = b.addExecutable(.{
            .name = executable.name,
            .root_module = mod,
        });

        const install_artifact = b.addInstallArtifact(
            exe,
            .{ .dest_dir = .{ .override = .{ .custom = "." } } },
        );
        b.default_step.dependOn(&install_artifact.step);
        const exe_artifact = b.addRunArtifact(exe);

        if (b.args) |args| {
            exe_artifact.addArgs(args);
        }

        const run_step = b.step(executable.name, executable.description);
        run_step.dependOn(&exe_artifact.step);

        const test_mod = b.addTest(.{
            .root_module = mod,
        });
        const test_name = "test " ++ executable.name;
        const test_step = b.step(test_name, test_name);
        const test_artifact = b.addRunArtifact(test_mod);
        test_step.dependOn(&test_artifact.step);
    }
}
