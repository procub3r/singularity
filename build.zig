const std = @import("std");

const DISK = "disk.img";

pub fn build(b: *std.Build) void {
    // build the disk image
    const disk_cmd = b.addSystemCommand(&.{ "nasm", "-fbin" });
    disk_cmd.addFileArg(.{ .path = "loader/main.asm" });
    const disk = disk_cmd.addPrefixedOutputFileArg("-o", DISK);

    const disk_install = b.addInstallFile(disk, DISK);
    b.getInstallStep().dependOn(&disk_install.step);

    // boot disk image in qemu
    const run_cmd = b.addSystemCommand(&.{"qemu-system-x86_64"});
    run_cmd.addArg("-drive");
    run_cmd.addPrefixedFileArg("format=raw,file=", disk);
    run_cmd.step.dependOn(&disk_cmd.step);

    const run_step = b.step("run", "Boot singularity in qemu");
    run_step.dependOn(&run_cmd.step);
}
