bits 16
org 0x7e00

_start:
    mov si, msg
    call print_string

hang:
    jmp hang

print_string:
    mov ah, 0x0e ; teletype

    lodsb
    or al, al
    jz done_printing
    int 0x10
    jmp print_string
done_printing:
    ret

msg db "Hello Sugat, form Stage 2", 0
