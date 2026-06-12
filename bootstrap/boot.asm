bits 16 ; tell NASM this is 16 bit code

; ------------------------------------------------------------------
; External symbols
; ------------------------------------------------------------------
extern print_string
extern print_new_line
extern number_to_str

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------

global BOOT_DRIVE ; Exports address where boot drive is stored for use in other stages

SECTION .text

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
    mov ah, 0x42                ; Extended read, disk read
    mov dl, [BOOT_DRIVE]        ; Read form boot drive
    mov si, DISK_ADDRESS_PACKET ; Set the address of DAP
    
    int 0x13         ; Bios disk interrupt
    jc disk_error    ; If read fails

read_success:
    mov si, read_success_msg ; print the message of read success
    call print_string        
    call print_new_line      ; print a new line
    jmp 0x7e00               ; jump to the newly loaded code 

disk_error:
    mov si, read_fail_msg ; print the disk read failure message
    call print_string
    jmp halt              ; halt as fallback

halt:
    cli ; clear interrupt flag
    hlt ; halt execution


; ===============================================================
;      This sections holds reading and writing data
; ===============================================================
SECTION .data align=4   ; writeable data 
BOOT_DRIVE db 0

align 4
DISK_ADDRESS_PACKET: 
    db 0x10   ; Size of packet (16B) 
    db 0x00   ; Rerserved 1 byte of DAP
    dw 0x01   ; Number of sectors to read
    dw 0x7e00 ; Target memory offset
    dw 0x00   ; Target memory segment
    dq 0x01   ; STARTING LBA

; ===============================================================
;                  Read-only data & Buffers
; ===============================================================
SECTION .rodata
hello db "hello world!",
new_line_str db 13, 10, 0
hello_len equ $ - hello

read_fail_msg db "Failed Sector 2 read", 0
read_success_msg db "Sector 2 loaded successfully!", 0


; ===============================================================
; ==== This puts the signature in its own linkable section ======
; ===============================================================
SECTION .boot_sig
    dw 0xaa55
