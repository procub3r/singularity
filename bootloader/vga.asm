; vga driver

vgaCursorPos: dw 0

vgaPrintString:
    push eax
    push edi
    mov di, word [vgaCursorPos]
.loopStart:
    mov al, byte [ebx]
    cmp al, 0
    je .loopEnd
    or ax, 0x0700
    mov [edi + 0x0b8000], word ax
    inc ebx
    add di, 2
    jmp .loopStart
.loopEnd:
    mov [vgaCursorPos], word di
    pop edi
    pop eax
    ret

vgaClearScreen:
    push edi
    xor edi, edi
.loopStart:
    cmp edi, 4000
    je .loopEnd
    mov [edi + 0x0b8000], word 0x0720
    add edi, 2
    jmp .loopStart
.loopEnd:
    pop edi
    ret
