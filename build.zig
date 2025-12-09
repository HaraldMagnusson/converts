const std = @import("std");
const Base = @import("src/shared.zig").Base;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bases = [_]Base{
        .dec,
        .hex,
        .bin,
    };

    const BaseCombo = struct { from: Base, to: Base };

    const base_combos = comptime blk: {
        const total_combo_count = bases.len * (bases.len - 1);
        var base_combos: [total_combo_count]BaseCombo = undefined;
        var index: usize = 0;
        for (bases) |from| {
            for (bases) |to| {
                if (from == to) continue;
                base_combos[index] = .{ .from = from, .to = to };
                index += 1;
            }
        }
        break :blk base_combos;
    };

    const test_step = b.step("test", "run all tests");

    inline for (base_combos) |combo| {
        const options = b.addOptions();
        options.addOption(Base, "convert_from", combo.from);
        options.addOption(Base, "convert_to", combo.to);

        const mod = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        mod.addOptions("build_config", options);

        const exe = b.addExecutable(.{
            .name = @tagName(combo.from) ++ "to" ++ @tagName(combo.to),
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

        const test_mod = b.addTest(.{
            .root_module = mod,
        });
        const test_artifact = b.addRunArtifact(test_mod);
        test_step.dependOn(&test_artifact.step);
    }
}
