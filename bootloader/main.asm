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

; load the rest of the bootloader
mov ah, 0x02   ; read function
mov al, 22   ; read 2 sectors (the kernel fits in 2 for now)
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
jnc .loadSuccess ; carry bit is set on error
jmp $ ; hang in case of error
.loadSuccess:
mov bx, loadedSectors
call printString

; enable the a20 line
call a20enable

; load gdt
mov bx, loadingGdt
call printString
cli ; disable interrupts
lgdt [gdtr]
mov bx, done
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
    ; the kernel is loaded to address 0x7e00
    ; it starts at the second sector in the disk image
    ; the entry point of an elf executable is stored at offset 0x18
    jmp 0x7e00 + 0x1000 ; jmp to the kernel entry point
    ; ^ this is a borderline inexcusable hack XD
    ; I determined the offset of the kernelMain function within the kernel elf
    ; manually by using hexdump. It happens to be 0x1000 for this particular
    ; kernel build. THIS IS NOT HOW THE KERNEL IS SUPPOSED TO BE LOADED!
    ; I just wanted some indication that my whole setup here works, and it does!

; strings
loadedSectors: db "loaded sectors", 0x0d, 0x0a, 0
loadingGdt: db "loading GDT... ", 0
done: db "done.", 0x0d, 0x0a, 0
failed: db "failed.", 0x0d, 0x0a, 0

; padding
times 510 - ($ - $$) db 0
dw 0xaa55 ; bootsector end
