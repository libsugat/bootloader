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

; from gdt.asm
extern gdt_descriptor

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------

global _start

SECTION .text
_start:
    mov si, msg
    call print_string

    call print_new_line

    
    call enable_a20
    jc a20_failed
    mov si, a20_enabled_msg
    call print_string
    call print_new_line

    cli
    push ds

    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    jmp 0x08:pmode

hang:
    hlt
    jmp hang

a20_failed:
    mov si, a20_fail_msg
    call print_string
    jmp hang

; ------------------ Temperory Real Mode ----------------
bits 32
pmode:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    jmp 0x18:pmode_16

bits 16
pmode_16:
    ; Flip the cr0 
    mov eax, cr0
    and eax, ~1
    mov cr0, eax

    ; Perform the 16-bit Far Jump to flush the pipeline
    jmp 0x0000:unreal_mode

; ----------------- Unreal Mode ------------------------
bits 16
unreal_mode:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    ; Lets try to prove we are in unreal mode

    mov ebx, 0x00200000 ; 2 MiB target address
    mov eax, 0xDEADBEEF ; Our test signature
    mov [ebx], eax      ; Write to high memory using our unreal portal!

    xor eax, eax        ; Clear the eax to 0, ensuring we dont cheat
    mov eax, [fs:ebx]   ; Read the data back from the 2 MiB mark into EAX
    cmp eax, 0xDEADBEEF ; Validate the signature
    jne proof_failed    ; jump will not happen if we are in unreal mode

    ; Print the success message
    mov si, urm_msg
    call print_string
    call print_new_line

    jmp hang

proof_failed:
    mov si, urm_failure
    call print_string
    jmp hang


; ===============================================================
;                  Read-only data & Buffers
; ===============================================================
SECTION .rodata
msg db "Hello Sugat, form Stage 2", 0
a20_enabled_msg db "Enabled A20...", 0
a20_fail_msg db "Bios failed to enable A20 line!!", 0
urm_msg db "Hello from Unreal Mode", 0
urm_failure db "Failed to enable Unreal mode", 0
