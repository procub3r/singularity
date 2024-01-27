bits 16
org 0x7c00

_start:
    ; first three bytes are used to jmp to the
    ; actual code, skipping the FAT metadata
    jmp .bpb_end
    db 0x00

    ; FAT metadata
    db "SNGLRTY " ; OEM name (8 bytes)
    ; fill dummy values
    times 25 db 0 ; BIOS Parameter Block
    times 26 db 0 ; extended BPB

.bpb_end:
    cli ; disable interrupts
    cld ; clear direction flag
    ; reset cs to 0 because the BIOS might
    ; load the bootsector to 0x07c0:0x0000
    jmp 0x0000:.reset_cs

.reset_cs:
    ; set segment registers to 0
    xor si, si
    mov ds, si
    mov ss, si
    mov es, si

    ; start the stack at 0x7c00, growing downwards.
    mov bp, 0x7c00
    mov sp, bp

    jmp $ ; halt

times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end
