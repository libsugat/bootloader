bits 16

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------
global check_a20
global enable_a20

; =================================================================  
; CODE SEGMENT: Executable Instructions
; =================================================================

SECTION .text

; =============================================================================
; Function: check_a20
; checks if a20 lines are enabled or gated
; Output:   AX = status of a20 lines
; Returns: 0 if a20 line is disabled (memory wraps around)
;          1 if a20 line is enabled (memory does not wrap around)
; =============================================================================
check_a20:
    pushf
    push ds
    push es
    push di
    push si

    ; Point to low memory
    xor ax, ax
    mov es, ax
    mov di, 0x7dfe

    ; Point to high memory
    not ax
    mov ds, ax      ; set DS = 0xffff
    mov si, 0x7e0e  ; 0xffff * 16 = 0x107DFE = 1mb + 0x7DFE

    ; Save original values
    push [es:di]
    push [ds:si]

    ; Write test data to low memory
    mov word [es:di], 0xb55b

    ; Write data to high memory
    mov word [ds:si], 0x5aa5

    ; check if low memory was over written
    cmp word [es:di], 0x5aa5

    ; Restore original values immediately to prevent corruption
    pop [ds:si]
    pop [es:di]

    ; deterine the return value
    mov ax, 0
    je check_a20__exit
    mov ax, 1

check_a20__exit:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

; =============================================================================
; Function: enable_a20
; Enables a20 lines to unlock 16mb ram
; Output:   CF = status of a20 lines
; Returns: 0 if a20 enabled successfully
;          1 if a20 enabling failed
; =============================================================================
enable_a20:
    pusha
    cli ; turn off interrupts
    clc

    call check_a20
    or ax, ax
    jnz enable_a20__exit

    ; Try Bios Interrupts to enable A20 line
    mov ax, 0x2401
    int 0x15
    ; for skipping complexity and being lazy I am not writing
    ; the wiki.osdev.org suggested full path
    ; for refernce next tries are keyboard controller, and then fast a20 gate
    
    call check_a20
    or ax, ax
    jnz enable_a20__exit
    
    stc
    
enable_a20__exit:
    popa
    sti
    ret
