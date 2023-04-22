; zero out all entries on all levels
xor ax, ax     ; mov 0
mov cx, 0x4000 ; into 0x4000 bytes
mov di, 0x1000 ; starting from address 0x1000.
cld            ; increment di while looping
rep stosb

mov eax, 0x1000 ; address of PMLT4
mov cr3, eax   ; set PMLT4 address

; point PML4 -> PDPT -> PD -> PT
mov word [0x1000], 0x2003
mov word [0x2000], 0x3003
mov word [0x3000], 0x4003

; identity map the first 512 * 4 = 2048KiB
mov bx, 0x03   ; 0b11 = present + read/write perms
mov cx, 512    ; loop 512 times
mov di, 0x4000 ; address of PT
.setEntry:
    mov word [di], bx
    add bx, 0x1000
    add di, 8 ; size of each entry is 8 bytes
    loop .setEntry

mov eax, cr4   ; read from cr4
or eax, 1 << 5 ; set PAE bit
mov cr4, eax   ; write to cr4
