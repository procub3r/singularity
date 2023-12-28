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
    mov dx, 0xa6d2
    call print_hex
    jmp $

times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end
