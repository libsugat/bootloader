bits 16
; =================================================================  
; Exported symbols
; =================================================================  
global build_memory_map

extern number_to_hex
extern number_to_str
extern print_string
extern print_new_line

SECTION .text

; =============================================================================
; Function: build_memory_map
; Input:    DI = Destination buffer pointer
; Output:   DI = Reset to buffer start.
;           AX = Number of entries
; Registers effected : EBX, ECX
; =============================================================================
build_memory_map:
    push di
    push cx
    push bp
    clc

    xor ebx, ebx
    xor bp, bp ; Using bp as counter
loop_entries:
    ; Force ACPI 3.0 extension bit to 1, but clear the rest of the 4 bytes
    mov dword [di + 20], 1

    xor eax, eax
    mov ax, 0xe820
    mov edx, 0x534D4150 ; Safety Signature "SMAP"
    mov ecx, 24         ; Ask for 24 bytes (ACPI 3.0 layout)
    int 0x15
    jc interrupt_error  ; If Carry Flag is set, it's an error or completion signal

    ; Secondary Safety net
    ; Verify that the BIOS actually returned 'SMAP' in EAX
    cmp eax, edx
    jne interrupt_error

    inc bp ; Increment the counter

    ; Check if this was the last entry
    test ebx, ebx
    jz build_memory_map__exit

    add di, 24        ; Increment the destination buffer forward for next entry
    jmp loop_entries  ; Loop back WITHOUT clearing EBX!

interrupt_error:
    stc ; Set carry to indicate Error
build_memory_map__exit:
    mov ax, bp ; Return count in AX
    pop bp
    pop cx
    pop di
    ret
