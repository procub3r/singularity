; print character from al
print_char:
    push ax
    mov ah, 0x0e
    int 0x10
    pop ax
    ret

; print 2 byte hex from dx
print_hex:
    push ax
    push cx
    mov al, '0'
    call print_char
    mov al, 'x'
    call print_char
    mov cx, 4 ; count iterations
.loop:
    cmp cx, 0
    je .end
    mov ax, dx
    and ax, 0xf000
    shr ax, 12
    cmp ax, 10
    jl .digit
    add ax, 7
.digit:
    add ax, 48
    call print_char
    shl dx, 4
    dec cx ; decrement iteration count
    jmp .loop
.end:
    pop cx
    pop ax
    ret
