a20enable:
    call a20check
    ; TODO: actually enable the A20 line.
    ; qemu enables it automatically for now.
    ; gotta implement it for bare metal.
    ret

a20EnabledMessage: db "The A20 line was already enabled", 0x0d, 0x0a, 0
a20DisabledMessage: db "The A20 line was not enabled by default", 0x0d, 0x0a, 0

; check if the A20 line is enabled
a20check:
    push ax
    push bx
    push di
    push si
    push es
    push ds
    xor ax, ax
    mov es, ax
    mov di, 0x0500 ; es:di = 0x0000:0x0500

    not ax
    mov ds, ax
    mov si, 0x0510 ; ds:si = 0xffff:0x0510

    ; save original values
    mov al, byte [es:di]
    push ax

    mov al, byte [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xff

    cmp byte [es:di], 0xff
    pop ax
    mov byte [ds:si], al
    pop ax
    mov byte [es:di], al
    pop ds
    pop es

    jne .enabled
    mov bx, a20DisabledMessage
    jmp .end
.enabled:
    mov bx, a20EnabledMessage
.end:
    call printString
    pop si
    pop di
    pop bx
    pop ax
    ret
