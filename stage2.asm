bits 16

extern print_string
extern print_new_line
extern number_to_str

extern BOOT_DRIVE

_start:
    mov si, msg
    call print_string

    call print_new_line

    ; xor ax, ax
    ; mov al, [BOOT_DRIVE]
    ; mov si, 0x9000
    ; call number_to_str

    ; mov si, di
    ; call print_string

hang:
    jmp hang

msg db "Hello Sugat, form Stage 2", 0
