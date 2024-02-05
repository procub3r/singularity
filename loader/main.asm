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
    ; don't continue if not booted from a hard disk
    cmp dl, 0x80
    mov al, 'D' ; disk error
    jne error

    ; set segment registers to 0
    xor si, si
    mov ds, si
    mov ss, si
    mov es, si

    ; start the stack at 0x7c00, growing downwards.
    mov bp, 0x7c00
    mov sp, bp

    ; check if bios extensions are supported
    mov ah, 0x41
    mov bx, 0x55aa
    int 0x13
    mov al, 'E' ; extensions not supported
    jc error

; there is a 33K ish size limitation on stage2 because of
; how it is being loaded. we won't be hitting the limit tho
load_stage2:
    ; ds:si = address of disk address packet
    push 0
    pop ds
    mov si, stage2_dapack

    ; number of sectors to read
    mov cx, ((stage2.end - stage2) >> 9) + 1

; read stage2 to memory sector by sector
.loop:
    mov ah, 0x42 ; bios read function (with LBA)
    int 0x13
    mov al, 'R' ; disk read error
    jc error

    ; each iteration reads 512 bytes of stage2,
    ; increment destination offset by 512
    add word [stage2_dapack.offset], 512
    ; LBA of the next sector to be read
    inc word [stage2_dapack.lba]
    dec cx
    jnz .loop

load_gdt:
    ; load gdt for long mode
    lgdt [gdtr]

adios_stage1:
    jmp 0x7e00 ; jump to stage2

; print error code in al to screen and hang
error:
    push 0xb800
    pop es
    mov ah, 0x0c
    mov word [es:0], ax
    jmp $

; gdt register contents
gdtr:
    dw gdt.end - gdt - 1 ; size of gdt
    dq gdt ; pointer to gdt

; 64 bit global descriptor table
gdt:
    dq 0x00 ; first entry is a null descriptor
    ; code segment descriptor
    dw 0x0000     ; limit
    dw 0x0000     ; base lo
    db 0x00       ; base mid
    db 0b10011010 ; access
    db 0b10100000 ; flags and limit hi(?)
    db 0x00       ; base hi

    ; data segment descriptor
    dw 0x0000     ; limit
    dw 0x0000     ; base lo
    db 0x00       ; base mid
    db 0b10010010 ; access
    db 0b11000000 ; flags and limit hi(?)
    db 0x00       ; base hi
.end:

; disk address packet structure for stage2
align 4 ; must be 4 byte aligned
stage2_dapack:
.size:    db 16 ; size of the packet in bytes
.zero:    db 0  ; unused, should be zero
.sectors: dw 1  ; read one sector. int 0x13 will be called
                ; in a loop to load the entirety of stage2
.offset:  dw 0x0000
.segment: dw 0x07e0 ; load sector to .segment:.offset
.lba:     dq 0x0001 ; LBA of stage2 (= stage2 >> 9)

times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end

stage2:
    times 4096 nop ; test multi-sector load
    mov al, 'S' ; stage2 load success!
    jmp error
.end:
