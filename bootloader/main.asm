[bits 16]
[org 0x7c00]

; reset cs to 0 because sometimes,
; the bios loads the bootsector to
; 0x07c0:0x0000 instead of 0x0000:0x7c00
jmp 0x0000:init

; includes
; %include "print.asm"

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

; gdt register
gdtr:
    dw gdt.end - gdt - 1 ; size of gdt
    dq gdt ; pointer to gdt

; bootloader init
init:
    cli ; clear the IF flag to disable
        ; maskable external interrupts

    ; initialize segment registers to 0
    mov ax, 0
    mov ds, ax
    mov ss, ax

    ; start the stack at 0x7c00, growing downwards.
    ; there is almost 30K of free space here!
    mov bp, 0x7c00
    mov sp, bp

    lgdt [gdtr] ; load gdt for long mode

    ; setup paging.
    ; zero out all entries on all levels
    xor ax, ax     ; mov 0
    mov cx, 0x4000 ; into 0x4000 bytes
    mov di, 0x1000 ; starting from address 0x1000.
    cld            ; increment di while looping
    rep stosb

    ; turns out, you can use 32 bit registers
    ; in 16 bit real mode! fun.
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
.set_page_entry:
    mov dword [di], ebx
    add ebx, 0x1000 ; next page
    add di, 8       ; size of each entry is 8 bytes
    dec cx
    jnz .set_page_entry

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
    ; and jump to long mode!
    jmp 0x08:long_mode

; long mode from here on out
[bits 64]
long_mode:
    jmp $ ; hang indefinitely

times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end
