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

setup_paging:
    ; zero out all entries on all levels
    xor ax, ax     ; mov 0
    mov cx, 0x4000 ; into 0x4000 bytes
    mov di, 0x1000 ; starting from address 0x1000.
    cld            ; increment di while looping
    rep stosb

    mov eax, 0x1000 ; address of PML4
    mov cr3, eax    ; must be set in cr3.
                    ; you can't mov it directly though

    ; identity map the first G
    mov word [0x1000], 0x2003 ; PML4[0] -> PDPT[0]
    mov word [0x2000], 0x3003 ; PDPT[0] -> PD[0]
    mov word [0x3000], 0x4003 ; PD[0] -> PT[0]

    ; also map a G from -2G to the same paddrs as the first G
    mov word [0x1ff8], 0x2003 ; PML4[-1] -> PDPT[0]
    mov word [0x2ff0], 0x3003 ; PDPT[-2] -> PD[0]

    ; indentity map the first 512 * 4 KiB = 2048 KiB
    mov ebx, 0x0003 ; addr 0x0000 or'd with flags 0b11.
                    ; 0b11 = page present + read/write perms
    mov cx, 512     ; loop 512 times
    mov di, 0x4000  ; address of PT

.loop:
    mov dword [di], ebx
    add ebx, 0x1000 ; next page
    add di, 8       ; size of each entry is 8 bytes
    dec cx
    jnz .loop

    ; enable PAE (Physical Address Extension)
    mov eax, cr4   ; read from cr4
    or eax, 1 << 5 ; set PAE bit
    mov cr4, eax   ; write to cr4

    ; switch to long mode
    mov ecx, 0xc0000080 ; EFER MSR
    rdmsr               ; read from it
    or eax, 1 << 8      ; set LM bit
    wrmsr               ; write back to it

    ; enable protection and paging
    mov eax, 0x80000001 ; set PE and PG bits
    mov cr0, eax        ; in cr0

    ; set cs to 0x08 (offset of code segment descriptor in gdt)
    ; and jump to stage2!
    jmp 0x08:stage2

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

bits 64
stage2:
    times 4096 nop ; test multi-sector load
    mov word [0xb8000], 0x0a00 | 'S'
    jmp $
.end:
