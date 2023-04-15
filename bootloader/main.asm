[org 0x7c00]
[bits 16]

cli ; disable interrupts

; load sectors other than the bootsector
mov bx, loadSectorMessage
call printString

mov ah, 0x02   ; read function
mov al, 0x02   ; read 2 sectors
mov cl, 0x02   ; start reading from the second sector
               ; the first sector is the bootsector
mov ch, 0x00   ; read from cylinder 0
; mov dl, 0x80 ; set drive number manually
               ; the BIOS should set it for us, however
mov dh, 0x00   ; read from head 0
push 0
pop es         ; sector(s) will be loaded to es:bx
mov bx, 0x7e00 ; load right next to the bootsector
               ; we have 638 KB of free memory from here (i think)

int 0x13
jc loadError ; the carry bit will be set if there was an error
mov bx, doneMessage
call printString

; enable the A20 line
call a20enable

; load gdt
mov bx, loadGdtMessage
call printString
lgdt [gdtr]
mov bx, doneMessage
call printString

; switch to protected mode
mov bx, switchingToPModeMessage
call printString

mov eax, cr0
or al, 1
mov cr0, eax
jmp 0x08:pMode ; cs is 0x08 in our gdt

loadError:
    mov bx, loadSectorErrorMessage
    call printString
    jmp $

loadSectorMessage: db "Loading additional sectors to memory... ", 0
loadSectorErrorMessage: db "Failed to load sectors to memory", 0
loadGdtMessage: db "Loading GDT... ", 0
switchingToPModeMessage: db "Switching to protected mode... ", 0
doneMessage: db "done!", 0x0d, 0x0a, 0

%include "a20.asm"
%include "gdt.asm"
%include "print.asm"

; pad with zeros till bootsector end
times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end

%include "pmode.asm"
