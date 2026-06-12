bits 16

; ------------------------------------------------------------------
; External symbols
; ------------------------------------------------------------------
extern print_string

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------
global number_to_hex

SECTION .test

; =============================================================================
; Function: number_to_hex
; Input:    AX = 16-bit unsigned integer, DI = Destination buffer pointer
; Output:   DI = Reset to string start. Buffer contains e.g., "1A2Fh", 0
;           AX = length of the string
; =============================================================================
number_to_hex:
    push bx
    push cx
    push dx
    push si

    mov si, di   ; Save start pointer to restore at exit
    xor cx, cx   ; CX will count digits pushed to stack

    ; --- Handle Zero Case ---
    test ax, ax
    jnz convert
    mov byte [di], '0'
    inc di
    jmp number_to_hex__exit

    ; --- Core Conversion Loop ---
convert:
next_digit:
    mov dx, ax
    and dx, 0x0f ; Isolate lowest 4 bits (nibble)
    shr ax, 0x04 ; Shift AX right to prepare next nibble

    cmp dl, 0x09 ; Check if nibble is 0-9 or A-F
    jbe is_digit
    add dl, 'A'-'9'-1 ; Adjust for ASCII gap between '9' and 'A' (adds 7)

is_digit:
    add dl, '0' ; Convert to final ASCII character
    push dx     ; Store on stack (reverses right-to-left extraction)
    inc cx

    test ax, ax
    jnz next_digit
    
    mov ax, cx

    ; --- Pop Digits to Buffer (Left-to-Right) ---
get_str:
    pop dx
    mov [di], dl
    inc di
    loop get_str

    ; --- Format Suffix & Finalize ---
    mov byte [di], 'h' ; Append hex suffix
    inc di
    
number_to_hex__exit:
    mov byte [di], 0 ; Null-terminate string
    mov di, si       ; Restore DI to starting pointer

    pop si
    pop dx
    pop cx
    pop bx
    ret


