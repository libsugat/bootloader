bits 16

; ------------------------------------------------------------------
; External symbols
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------

global memcpy

; =================================================================  
; CODE SEGMENT: Executable Instructions
; =================================================================

SECTION .text
; ===================================================================
; Function: memcpy
; Copies a block of memory between distinct segments using native pairs.
;
; Inputs: DS:SI = Source Address (Segment:Offset)
;         ES:DI = Destination Address (Segment:Offset)
;         CX    = Number of bytes to copy
; Flags preserved
; ===================================================================
memcpy:
    pushf               ; Save flags (preserves Direction Flag)
    push di
    push si
    cld                 ; Clear Direction Flag (increment forward)
    rep movsb           ; Blazing fast copy from [DS:SI] to [ES:DI]
    pop si
    pop di
    popf                ; Restore flags
    ret
