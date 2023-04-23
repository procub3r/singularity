[org 0x7c00]
[bits 16]

; reset cs to 0 because some bios'
; load the bootsector to 0x07c0:x0000
; instead of 0x0000:0x7c00.
jmp 0x00:init

; init
init:
mov ax, 0
mov ds, ax
mov ss, ax
mov bp, 0x7c00
mov sp, bp

; load the kernel
mov ah, 0x02   ; read function
mov al, 22     ; read 22 sectors (the kernel fits in 22 for now)
mov cl, 0x02   ; start reading from the second sector
               ; the first sector is the bootsector
mov ch, 0x00   ; read from cylinder 0
; mov dl, 0x80 ; set drive number manually
               ; the BIOS should set it for us, however
mov dh, 0x00   ; read from head 0
push 0
pop es         ; sector(s) will be loaded to es:bx

elf_base equ 0x7e00 ; load right next to the bootsector
mov bx, elf_base    ; we have 638 KB of free memory from here (i think)

int 0x13
jnc .loadSuccess ; carry bit is set on error
jmp $ ; hang in case of error
.loadSuccess:
mov bx, loaded_sectors
call printString

; enable the a20 line
call a20enable

; load gdt
cli ; disable interrupts
lgdt [gdtr]
mov bx, loaded_gdt
call printString

; setup paging
%include "paging.asm"

mov ecx, 0xc0000080 ; EFER MSR
rdmsr               ; read from it
or eax, 1 << 8      ; set LM bit (long mode, here we come!)
wrmsr               ; write back to it

mov eax, 0x80000001 ; set PE and PG bits in cr0
mov cr0, eax        ; to enable protection and paging

; set cs to 0x08 and jump to 64 bit code!
jmp 0x08:longMode

; includes
%include "biosprint.asm"
%include "a20.asm"
%include "gdt.asm"

[bits 64]
longMode:
    %include "loadkernel.asm"
    ; ^ loadkernel.asm should load and jump to the kernel

; strings
loaded_sectors: db "loaded sectors", 0x0d, 0x0a, 0
loaded_gdt: db "loaded GDT", 0x0d, 0x0a, 0

; padding
times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end
