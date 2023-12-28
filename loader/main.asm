jmp $ ; infinite loop
times 510 - ($ - $$) db 0 ; padding
dw 0xaa55 ; bootsector end
