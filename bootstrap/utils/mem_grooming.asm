bits 16
; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------
global clear_bytes

SECTION .text
; =============================================================================
; Function: clear_bytes
; Input:    ES:DI = lower 2 bytes of 64 bit target lba
;           CX = Number of bytes
;
; =============================================================================
clear_bytes:
    pushf
    push ax
    cld
    xor al, al
    rep stosb

    pop ax
    popf
    ret

