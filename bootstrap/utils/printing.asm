bits 16

global number_to_str
global print_string
global print_new_line

; --- Converts number in AX to printable null terminating ascii string ---
; inputs: destination of the string in di, input number in ax
; return: string length in ax
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
    jmp number_to_str_done
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
    
number_to_str_done:
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
    jz done_printing
    int 0x10
    jmp print_string
done_printing:
    ret

; --- prints a new line ---
; affected registers : AX
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

