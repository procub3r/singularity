; elf header absolute offsets
e_entry     equ elf_base + 0x18
e_phoff     equ elf_base + 0x20
e_phentsize equ elf_base + 0x36
e_phnum     equ elf_base + 0x38

; program header relative offsets
p_type   equ 0x00
p_offset equ 0x08
p_vaddr  equ 0x10
p_filesz equ 0x20
p_memsz  equ 0x28

movzx r8, word [e_phnum] ; number of phdrs
movzx r9, word [e_phentsize] ; size of each phdr
mov r10, qword [elf_base + e_phoff] ; offset to first phdr
add r10, elf_base ; absolute pointer to first phdr

loadSector:
    cmp r8, 0
    jz jumpToKernel
    cmp dword [r10 + p_type], 0x01
    jne .skipLoading ; the segment is not loadable

    mov rsi, [r10 + p_offset] ; offset to segment
    add rsi, elf_base         ; absolute pointer to segment
    mov rdi, [r10 + p_vaddr]  ; absolute destination of segment

    mov rcx, [r10 + p_filesz]
    mov r11, rcx ; store for later use
    rep movsb ; copy the segment to its destination

    ; rdi already points to the end of the
    ; segment copied over from the elf file
    mov al, 0
    mov rcx, [r10 + p_memsz]
    sub rcx, r11 ; rcx = memsz - filesz
    rep stosb    ; zero out the remaining bytes

.skipLoading:
    dec r8
    add r10, r9
    jmp loadSector

jumpToKernel:
    jmp [e_entry]
