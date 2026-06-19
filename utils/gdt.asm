bits 16
; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------
global gdt_descriptor

; =================================================================  
; CODE SEGMENT: Executable Instructions
; =================================================================
SECTION .text

SECTION .rodata align=8
align 8
gdt_start:
    ; 1. Null Descriptor
    dq 0x0
    
    ; 2. Kernel Code Segment Descriptor
    ; Base: 0x00000000, Limit: 0xfffff
    ; Access byte: 0x9a (Present, Ring 0, Executable, Read/Write)
    ; Flags:       0xc  (32-bit mode, 4KB granularity)
    dw 0xFFFF    ; limit (bits 0-15)
    dw 0x0000    ; base addr (bits 0-15)
    db 0x00      ; base addr (bits 16-23)
    db 10011010b ; access byte
    db 11001111b ; flags (bits 0-3), limit (bits 16-19)
    db 0x00      ; base addr (bits 24-31)

    ; 3. Kernel Data Segment Descriptor (Offset 0x10)
    ; Base: 0x00000000, Limit: 0xfffff
    ; Access byte: 0x92 (Present, Ring 0, Non-executable, Read/Write)
    ; Flags:       0xc  (32-bit mode, 4KB granularity)
    dw 0xffff    ; Limit (bits 0-15)
    dw 0x0000    ; Base (bits 0-15)
    db 0x00      ; Base (bits 16-23)
    db 10010010b ; Access Byte (0x92)
    db 11001111b ; Flags (4 bits) + Limit (bits 16-19)
    db 0x00      ; Base (bits 24-31)

    ; 4. Segment for Unreal Mode Code
    ; Base: 0x00000000, Limit: 0xfffff
    ; Access byte: 0x9a (Present, Ring 0, Executable, Read/Write)
    ; Flags:       0x00 (16-bit mode, no 4KB granularity)
    dw 0xFFFF    ; limit (bits 0-15)
    dw 0x0000    ; base addr (bits 0-15)
    db 0x00      ; base addr (bits 16-23)
    db 10011010b ; access byte
    db 00000000b ; flags (bits 0-3), limit (bits 16-19)
    db 0x00      ; base addr (bits 24-31)

gdt_end:

; --- The GDT Pointer (Exported) ---
gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; 16-bit Size (Limit)
    dd gdt_start                ; 32-bit Base Address
