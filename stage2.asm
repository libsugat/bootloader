bits 16

; ------------------------------------------------------------------
; External symbols
; ------------------------------------------------------------------

; Utility Functions from Sector 1 (bootstrap)
extern print_string
extern print_new_line
extern number_to_str
; Memory mapped variables
extern BOOT_DRIVE

; from printing.asm
extern number_to_hex

; from a20_utilities.asm
extern check_a20
extern enable_a20

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------

global _start


SECTION .text
_start:
    mov si, msg
    call print_string

    call print_new_line
    
    mov ax, 0xaa55
    mov di, 0x9000
    call number_to_hex

    mov si, di
    call print_string
    call print_new_line
    
    call enable_a20
    jc a20_failed
    mov si, a20_enabled_msg
    call print_string

hang:
    hlt
    jmp hang

a20_failed:
    mov si, a20_fail_msg
    call print_string
    jmp hang


SECTION .rodata
msg db "Hello Sugat, form Stage 2", 0
a20_enabled_msg db "Enabled A20...", 0
a20_fail_msg db "Bios failed to enable A20 line!!", 0
