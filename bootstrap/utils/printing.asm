bits 16

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------

global number_to_str
global print_string
global print_new_line

SECTION .text
; =============================================================================
; Function: number_to_hex
; Input:    AX = 16-bit unsigned integer, DI = Destination buffer pointer
; Output:   DI = Reset to string start. Buffer contains e.g., "1424", 0
;           AX = length of the string
; =============================================================================
number_to_str:
    push bx
    push cx
    push dx
    push si

    mov si, di
    xor cx, cx

    test ax, ax
    jnz convert
    mov byte [di], '0'
    inc di
    jmp number_to_str__exit
convert:
    mov bx, 10
next_digit:
    xor dx, dx
    div bx

    add dl, '0'
    push dx
    inc cx

    test ax, ax
    jnz next_digit
    
    mov ax, cx

get_str:
    pop dx
    mov [di], dl
    inc di
    loop get_str
    
number_to_str__exit:
    mov byte [di], 0
    mov di, si

    pop si
    pop dx
    pop cx
    pop bx
    ret

; --- Teletypes Null terminating ASCII string to BIOS display output ---
; The following functions prints a null terminating ascii string
; SI = Source Address of the string
; Affected registers : AX, AH
print_string:
    mov ah, 0x0e ; teletype
    lodsb
    or al, al
    jz print_string__exit
    int 0x10
    jmp print_string
print_string__exit:
    ret

; --- prints a new line ---
; affected registers : ax
print_new_line:
    mov ah, 0x0e ; teletype
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    ; push si
    ; mov si, new_line_str
    ; call print_string
    ; pop si
    ret

