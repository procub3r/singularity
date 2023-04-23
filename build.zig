const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Target = std.Target;

pub fn build(b: *std.Build) void {
    const target = CrossTarget{
        .cpu_arch = Target.Cpu.Arch.x86_64,
        .cpu_features_add = blk: {
            var add_features = Target.Cpu.Feature.Set.empty;
            add_features.addFeature(@enumToInt(Target.x86.Feature.soft_float));
            break :blk add_features;
        },
        .cpu_features_sub = blk: {
            var sub_features = Target.Cpu.Feature.Set.empty;
            sub_features.addFeature(@enumToInt(Target.x86.Feature.x87));
            sub_features.addFeature(@enumToInt(Target.x86.Feature.mmx));
            sub_features.addFeature(@enumToInt(Target.x86.Feature.sse));
            sub_features.addFeature(@enumToInt(Target.x86.Feature.sse2));
            sub_features.addFeature(@enumToInt(Target.x86.Feature.avx));
            sub_features.addFeature(@enumToInt(Target.x86.Feature.avx2));
            break :blk sub_features;
        },
        .os_tag = Target.Os.Tag.freestanding,
        .abi = Target.Abi.none,
    };

    const optimize = b.standardOptimizeOption(.{});
    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .path = "kernel/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    kernel.setLinkerScriptPath(.{ .path = "./linker.ld" });
    const copy_kernel = b.addInstallBinFile(kernel.getOutputSource(), "kernel.elf");

    const build_kernel = b.step("kernel", "Build the kernel");
    build_kernel.dependOn(&copy_kernel.step);

    b.default_step = build_kernel;
}
