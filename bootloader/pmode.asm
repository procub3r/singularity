[bits 32]

%include "vga.asm"

welcomeToPMode: db "Welcome to protected mode! We have been expecting you...", 0

pMode:
    call vgaClearScreen
    mov ebx, welcomeToPMode
    call vgaPrintString
    jmp $
