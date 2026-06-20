bits 16

; ------------------------------------------------------------------
; External symbols
; ------------------------------------------------------------------

extern print_string
extern number_to_hex
extern print_new_line
extern read_sectors
extern clear_bytes

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------

global memcpy
global memcpy_unreal
global clear_bytes_unreal

; =================================================================  
; CODE SEGMENT: Executable Instructions
; =================================================================

SECTION .text
; ===================================================================
; Function: memcpy
; Copies a block of memory between distinct segments using native pairs.
;
; Inputs: DS:ESI = Source Address (Segment:Offset)
;         ES:EDI = Destination Address (Segment:Offset)
;         ECX    = Number of bytes to copy
; Flags preserved
; ===================================================================
memcpy:
    cli
    pushf               ; Save flags (preserves Direction Flag)
    push edi
    push esi
    cld                 ; Clear Direction Flag (increment forward)
    rep movsd           ; Blazing fast copy from [DS:SI] to [ES:DI]
    pop esi
    pop edi
    popf                ; Restore flags
    ret

; ===================================================================
; Function: memcpy
; Copies a block of memory between distinct segments using native pairs.
;
; Inputs: DS:ESI = Source Address (Segment:Offset)
;         EDI = Destination Address (Segment:Offset)
;         ECX    = Number of bytes to copy
; Requires cpu in unreal mode, and FS to be unaltered
; Flags preserved
; EDI : not preserved
; ===================================================================
memcpy_unreal:
    cli
    pushf               ; Save flags (preserves Direction Flag)
    push esi
    push ax

    test ecx, ecx
    jz memcpy_unreal__done

memcpy_unreal__loop:
    mov al, [ds:esi]
    mov byte [fs:edi], al
    inc esi
    inc edi
    dec ecx
    jnz memcpy_unreal__loop
memcpy_unreal__done:
    
    pop ax
    pop esi
    popf                ; Restore flags
    ret

; =============================================================================
; Function: clear_bytes_unreal
; Input:    EDI = lower 2 bytes of 64 bit target lba
;           ECX = Number of bytes
; =============================================================================
clear_bytes_unreal:
    push ax
    xor eax, eax

    test ecx, ecx
    jz clear_bytes_unreal__done

clear_bytes_unreal__loop:
    mov byte [fs:edi], al
    inc edi
    dec ecx
    jnz clear_bytes_unreal__loop

clear_bytes_unreal__done:
    pop ax
    ret
