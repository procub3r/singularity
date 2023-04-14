[org 0x7c00]
[bits 16]

mov bx, message
call printString

mov al, 0x0a
call printChar
mov al, 0x0d
call printChar

mov dx, 0x1a2b
call printHex
mov bx, comment
call printString
jmp $ ; stop execution and hang indefinitely here

comment: db " # We can print hexadecimal numbers!", 0
message: db "Hello, we have been expecting you...", 0

%include "print.asm"

; pad with zeros till bootsector end
times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end
