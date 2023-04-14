; print dx in hexadecimal format
printHex:
    push ax
    mov al, '0'
    call printChar
    mov al, 'x'
    call printChar
.loopStart:
    cmp dx, 0
    je .loopEnd
    mov ax, dx
    and ax, 0xf000
    shr ax, 12
    cmp ax, 0x0a
    jl .digit
    add ax, 7
.digit:
    add ax, 0x30
    call printChar
    shl dx, 4
    jmp .loopStart
.loopEnd:
    pop ax
    ret

; print string from bx
printString:
    push ax
    push si
    mov si, 0
.loopStart:
    cmp [bx + si], byte 0
    je .loopEnd
    mov al, [bx + si]
    call printChar
    inc si
    jmp .loopStart
.loopEnd:
    pop si
    pop ax
    ret

; print char from al
printChar:
    push ax
    mov ah, 0x0e
    int 0x10
    pop ax
    ret
