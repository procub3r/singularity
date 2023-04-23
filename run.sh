mkdir -p bin/

# build the bootloader into a raw disk image
nasm -fbin -Ibootloader/ bootloader/main.asm -o bin/bootloader.img

# build the kernel as an elf
zig build -Doptimize=ReleaseSmall

# create the final disk image with bootloader at the starting
cp bin/bootloader.img bin/disk.img

# put the kernel elf right after the bootloader in the disk image
cat zig-out/bin/kernel.elf >> bin/disk.img

# boot from the disk image
qemu-system-x86_64 -d int --no-reboot --no-shutdown -fda bin/disk.img
# qemu-system-x86_64 -drive format=raw,file=bin/bootloader.img
