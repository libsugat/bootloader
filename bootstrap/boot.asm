bits 16 ; tell NASM this is 16 bit code
; org 0x7c00 ; tell NASM to start outputting stuff at offset 0x7c00

extern print_string
extern print_new_line
extern number_to_str
global BOOT_DRIVE

jmp 0x00:boot ; For some weird bios that uses 0x07c0:0x00 for memory address
boot:
    ; setup segment registers to be at 0x0
    ; setup stack at locations 0x7000
    mov [BOOT_DRIVE], dl ; save the boot drive number
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000
    sti

    ; Print hello world
    mov si, hello
    call print_string

    ; lets print a number
    ; why not try the boot drive number
    xor ax, ax
    mov al, [BOOT_DRIVE]
    mov di, 0x9000
    call number_to_str

    ; print the number
    mov si, di
    call print_string
    call print_new_line

    ; lets try reading second sector form the disk
    mov ah, 0x02 ; function code of interupt (read sector)
    mov al, 0x01 ; read one sector from storage (512bytes)
    mov bx, 0x7e00 ; Set the Offset (BX) to 0x8000
                   ; The data will be loaded to physical RAM 0x08000
    mov ch, 0x0  ; cylinder = 0
    mov dh, ch   ; head = 0
    mov cl, 0x02 ; sector = 2
    mov dl, [BOOT_DRIVE]
    
    int 0x13         ; Bios disk interrupt
    jc disk_error    ; If read fails
    jmp read_success ; If read succed

disk_error:
    mov si, read_fail_msg ; print the disk read failure message
    call print_string
    jmp halt              ; halt as fallback

read_success:
    mov si, read_success_msg ; print the message of read success
    call print_string        
    call print_new_line      ; print a new line
    jmp 0x7e00               ; jump to the newly loaded code 

halt:
    cli ; clear interrupt flag
    hlt ; halt execution

; ==== This sections holds reading and writing data ====
BOOT_DRIVE db 0

hello db "hello world!",
new_line_str db 13, 10, 0
hello_len equ $ - hello

read_fail_msg db "Failed Sector 2 read", 0
read_success_msg db "Sector 2 loaded successfully!", 0

; ; ==== Padding with 0x00 ====
; times 510 - ($-$$) db 0 ; pad remaining 510 bytes with zeroes
; ; ==== Boot Signature ====
; dw 0xaa55 ; magic bootloader magic - marks this 512 byte sector bootable!

