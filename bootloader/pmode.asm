[bits 32]

%include "vga.asm"

welcomeToPModeMessage: db "Welcome to protected mode! ", 0
settingUpPagingMessage: db "Setting up paging... ", 0
switchingToLongModeMessage: db "Switching to long mode... ", 0
pagingSetUpMessage: db "Paging set up! ", 0

pMode:
    ; clear screen and begin printing using the vga driver
    call vgaClearScreen
    mov ebx, welcomeToPModeMessage
    call vgaPrintString

    ; set up paging
    mov ebx, settingUpPagingMessage
    call vgaPrintString

    ; point cr3 to PMLT4
    mov edi, 0x1000 ; address of PMLT4
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096   ; for all edi from 0x1000 to (0x1000 + ecx)
    rep stosd       ; set [edi] to eax (0); zero the page tables
    mov edi, cr3    ; restore original value of edi (&PMLT4)

    ; link all other tables
    mov dword [edi], 0x2003
    add edi, 0x1000
    mov dword [edi], 0x3003
    add edi, 0x1000
    mov dword [edi], 0x4003
    add edi, 0x1000

    ; map the first 2KiB of memory
    mov ebx, 0x03
    mov ecx, 512 ; run the loop 512 times to set 512 entries

.setEntry:
    mov dword [edi], ebx
    add ebx, 0x1000
    add edi, 8
    loop .setEntry

    ; enable PAE
    mov eax, cr4
    or eax, 0b100000 ; set PAE bit to enable PAE
    mov cr4, eax

    ; switch to long mode
    mov ecx, 0xc0000080
    rdmsr
    or eax, 1 << 8 ; set LM bit to switch to long mode
    wrmsr

    ; enable paging
    mov eax, cr0
    or eax, 1 << 31 ; set PG bit to enable paging
    mov cr0, eax

    ; load 64 bit gdt
    lgdt [gdtr64]

    jmp 0x08:lModeRocks

[bits 64]
lModeRocks:
    ; long mode!!
    jmp $ ; a bit anticlimactic innit
