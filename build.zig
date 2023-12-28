const std = @import("std");

const INSTALL_PATH = "bin/";
const LOADER = "loader.bin";

pub fn build(b: *std.Build) void {
    b.install_path = INSTALL_PATH;

    // build the loader with nasm
    const loader_cmd = b.addSystemCommand(&.{ "nasm", "-fbin", "-Iloader/" });
    loader_cmd.addFileArg(.{ .path = "loader/main.asm" });
    const loader = loader_cmd.addPrefixedOutputFileArg("-o", LOADER);

    // // install the loader to INSTALL_PATH
    // const loader_install = b.addInstallFile(loader, LOADER);
    // b.getInstallStep().dependOn(&loader_install.step);

    // run singularity on qemu
    const run_cmd = b.addSystemCommand(&.{"qemu-system-x86_64"});
    run_cmd.addArg("-drive");
    run_cmd.addPrefixedFileArg("format=raw,file=", loader);
    run_cmd.step.dependOn(b.getInstallStep());

    // run step
    const run_step = b.step("run", "Run singularity");
    run_step.dependOn(&run_cmd.step);
}
