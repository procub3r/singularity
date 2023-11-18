const std = @import("std");

pub fn build(b: *std.Build) void {
    // Target a freestanding environment which uses just the general purpose registers.
    const target = std.zig.CrossTarget{
        .cpu_arch = .x86_64,
        .cpu_features_add = blk: {
            var add_features = std.Target.Cpu.Feature.Set.empty;
            // TODO: add features.
            break :blk add_features;
        },
        .cpu_features_sub = blk: {
            var sub_features = std.Target.Cpu.Feature.Set.empty;
            // TODO: remove features.
            break :blk sub_features;
        },
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
    };

    // Use the standard optimization options. I'll probably build using -Doptimize=ReleaseSmall
    // because I haven't figured out how to make use of debug info yet.
    const optimize = b.standardOptimizeOption(.{});

    // kernel elf executable
    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .path = "kernel/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Use custom linker script to load to the higher half, among other things.
    kernel.setLinkerScript(.{ .path = "linker.ld" });
    b.installArtifact(kernel);
}
