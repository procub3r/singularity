const std = @import("std");

const INSTALL_PATH = "bin/";
const LOADER = "bootloader.bin";

pub fn build(b: *std.Build) void {
    b.install_path = INSTALL_PATH;

    // build the bootloader with nasm
    const bootloader_cmd = b.addSystemCommand(&.{ "nasm", "-fbin", "-Ibootloader/" });
    bootloader_cmd.addFileArg(.{ .path = "bootloader/main.asm" });
    const bootloader = bootloader_cmd.addPrefixedOutputFileArg("-o", LOADER);

    // install the bootloader to INSTALL_PATH
    const bootloader_install = b.addInstallFile(bootloader, LOADER);
    b.getInstallStep().dependOn(&bootloader_install.step);

    // run singularity on qemu
    const run_cmd = b.addSystemCommand(&.{"qemu-system-x86_64"});
    run_cmd.addArg("-drive");
    run_cmd.addPrefixedFileArg("format=raw,file=", bootloader);
    run_cmd.step.dependOn(b.getInstallStep());

    // run step
    const run_step = b.step("run", "Run singularity");
    run_step.dependOn(&run_cmd.step);

    // debug singularity on qemu
    const debug_cmd = b.addSystemCommand(&.{"qemu-system-x86_64"});
    debug_cmd.addArgs(&.{ "-d", "int", "-no-shutdown", "-no-reboot" });
    debug_cmd.addArg("-drive");
    debug_cmd.addPrefixedFileArg("format=raw,file=", bootloader);
    debug_cmd.step.dependOn(b.getInstallStep());

    // debug step
    const debug_step = b.step("debug", "Debug singularity");
    debug_step.dependOn(&debug_cmd.step);
}
