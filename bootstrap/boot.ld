SECTIONS {
    . = 0x7C00;
    .text :
    {
        *boot.o(.text*)
        *printing.o(.text*)
    }
    ASSERT(
        SIZEOF(.text)<=446,
        "MBR code too large"
    )

    . = 0x7DBE;
    .partition :
    {
        BYTE(0)
        . += 63;
    }

    . = 0x7DFE;
    .sig :
    {
        SHORT(0xAA55)
    }
}
