RO_DATA_ALIGN = 8;
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

    .rodata : ALIGN(RO_DATA_ALIGN) SUBALIGN(RO_DATA_ALIGN)
    {
        *stage2.o(.rodata*)
        *(.rodata*)
    }
}
