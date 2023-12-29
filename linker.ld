ENTRY(kernelMain)

SECTIONS {
    . = 0xffffffff80100000;
    .text : {
        *(.text)
    }
}
