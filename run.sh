nasm -fbin -Ibootloader/ bootloader/main.asm -o bin/disk.img
qemu-system-x86_64 -drive format=raw,file=bin/disk.img
