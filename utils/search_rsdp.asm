bits 16

; ------------------------------------------------------------------
; External symbols
; ------------------------------------------------------------------
extern print_string
extern print_new_line
extern number_to_hex

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------

extern search_rsdp

; ----- Useful memory addresses and Constants ----
RSDP_SIGNATURE_LOW      equ 0x20445352; "RSD "
RSDP_SIGNATURE_HIGH     equ 0x20525450; "PTR "

SECTION .text
; ====================================================================
; search_quadword
; Searches memory for a 64-bit Quadword in Real / Unreal Mode.
; Given that it has to be 16bytes aligned
;
; Inputs:
;   ES:EDI  - Starting memory address (ES must have 4GB descriptor in Unreal mode)
;   EDX:EAX - 64-bit value to search (EDX = High 32 bits, EAX = Low 32 bits)
;   ECX     - Search length in bytes
;
; Outputs:
;   ZF      - Set (1) if Quadword found, Cleared (0) if not found
;   EDI     - Pointer to the EXACT START of the matching 64-bit quadword
;   ECX     - Remaining bytes in range
; ====================================================================
search_quadword:
    jecxz .quadword_not_found ; for condition where the search size is 0
    ; Check 16 byte alignment of edi and ecx
    test edi, 0x0f
    jnz .quadword_not_found
    test ecx, 0x0F
    jnz .quadword_not_found

.search_loop:
    cmp eax, [edi]
    jnz .search_loop_continue

    cmp edx, [edi + 4]
    jz .quadword_found

.search_loop_continue:
    add edi, 16
    sub ecx, 16
    jnz .search_loop

.quadword_not_found:
    xor edi, edi    ; Return null
    ret

.quadword_found:
    ret

; ====================================================================
; search_rsdp
; Search rsdp i.e RSDP_STRUCT
;
; Outputs:
;   CF      - Set (1) if rsdp not found, Cleared (0) if not found
;   EDI     - Pointer to the RSDP struct
; ====================================================================
search_rsdp:
    clc
    ; Search in EDBA starting at 0x40E for 1kib
    mov di, [0x40E]
    shl edi, 4
    test edi, edi
    jz .bios_search

    mov eax, RSDP_SIGNATURE_LOW
    mov edx, RSDP_SIGNATURE_HIGH
    mov ecx, 1024                   ; 1kib
    call search_quadword
    jnz .found

.bios_search:
    ; Search in EDBA starting 0xE0000 to 0xFFFFF
    mov eax, RSDP_SIGNATURE_LOW
    mov edx, RSDP_SIGNATURE_HIGH
    mov edi, 0xE0000
    mov ecx, 0x20000
    call search_quadword
    jz .found
    ; If we reach here it simply means that RSDP was not found
    xor edi, edi
    stc     ; Set carry flag
    jmp .return

.found:
    ; TODO: write code for performing checksum
    clc     ; Clear carry flag

.return:
    ret

SECTION .rodata
