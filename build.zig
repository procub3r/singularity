const std = @import("std");

const LOADER = "bootloader.bin";
const KERNEL = "kernel.elf";

pub fn build(b: *std.Build) void {
    // build the bootloader with nasm
    const bootloader_cmd = b.addSystemCommand(&.{ "nasm", "-fbin", "-Ibootloader/" });
    bootloader_cmd.addFileArg(.{ .path = "bootloader/main.asm" });
    const bootloader = bootloader_cmd.addPrefixedOutputFileArg("-o", LOADER);

    // install the bootloader
    const bootloader_install = b.addInstallFile(bootloader, LOADER);
    b.getInstallStep().dependOn(&bootloader_install.step);

    // build the kernel
    // target a freestanding environment with the bare minimum cpu features
    const target = std.zig.CrossTarget{
        .cpu_arch = .x86_64,
        .cpu_features_add = blk: {
            const add_features = std.Target.Cpu.Feature.Set.empty;
            break :blk add_features;
        },
        .cpu_features_sub = blk: {
            const sub_features = std.Target.Cpu.Feature.Set.empty;
            break :blk sub_features;
        },
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
    };

    // use the standard optimization options
    const optimize = b.standardOptimizeOption(.{});

    // kernel elf binary
    const kernel = b.addExecutable(.{
        .name = KERNEL,
        .root_source_file = .{ .path = "kernel/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // use custom linker script to load to the higher half, among other things
    kernel.setLinkerScript(.{ .path = "linker.ld" });
    b.installArtifact(kernel); // install the kernel

    // run singularity on qemu
    const run_cmd = b.addSystemCommand(&.{"qemu-system-x86_64"});
    run_cmd.addArg("-drive");
    run_cmd.addPrefixedFileArg("if=floppy,format=raw,file=", bootloader);
    run_cmd.step.dependOn(b.getInstallStep());

    // run step
    const run_step = b.step("run", "Run singularity");
    run_step.dependOn(&run_cmd.step);

    // debug singularity on qemu
    const debug_cmd = b.addSystemCommand(&.{"qemu-system-x86_64"});
    debug_cmd.addArgs(&.{ "-d", "int", "-no-shutdown", "-no-reboot" });
    debug_cmd.addArg("-drive");
    debug_cmd.addPrefixedFileArg("if=floppy,format=raw,file=", bootloader);
    debug_cmd.step.dependOn(b.getInstallStep());

    // debug step
    const debug_step = b.step("debug", "Debug singularity");
    debug_step.dependOn(&debug_cmd.step);
}
