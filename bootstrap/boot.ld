SECTIONS {
    . = 0x7C00;
    .text :
    {
        *boot.o(.text*)
        *(.text*)

        *boot.o(.data*)
        *(.data*)

        *boot.o(.rodata*)
        *(.rodata*)
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
        *boot.o(.boot_sig)
    }
}
