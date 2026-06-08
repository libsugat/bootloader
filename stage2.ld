SECTIONS {
    . = 0x7e00;

    .text :
    {
        *stage2.o(.text*)
        *(.text*)
    }

    .data :
    {
        *stage2.o(.data*)
        *(.data*)
    }
    .rodata :
    {
        *stage2.o(.rodata*)
        *(.rodata*)
    }
}
