[bits 16]
[org 0x7c00]

; reset cs to 0 because sometimes,
; the bios loads the bootsector to
; 0x07c0:0x0000 instead of 0x0000:0x7c00
jmp 0x0000:init

; includes
%include "print.asm"

; bootloader init
init:
    cli ; clear the IF flag to disable
        ; maskable external interrupts

    lgdt [gdtr] ; load gdt for long mode
    jmp $ ; hang indefinitely

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

times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end
