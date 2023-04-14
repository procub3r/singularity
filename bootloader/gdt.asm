gdtr:
    dw gdt.end - gdt - 1 ; size of gdt
    dd gdt ; offset to gdt

gdt:
    dq 0x00 ; set first entry to null

    ; code segment descriptor
    dw 0xffff     ; limit
    dw 0x0000     ; base lo
    db 0x00       ; base mid
    db 0b10011010 ; access
    db 0b11001111 ; flags and limit hi(?)
    db 0x00       ; base hi

    ; data segment descriptor
    dw 0xffff     ; limit
    dw 0x0000     ; base lo
    db 0x00       ; base mid
    db 0b10010010 ; access
    db 0b11001111 ; flags and limit hi(?)
    db 0x00       ; base hi

    .end:
