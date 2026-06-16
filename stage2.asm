bits 16

; =================================================================  
; External symbols
; =================================================================  

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

extern build_memory_map
; =================================================================  
; Exported symbols
; =================================================================  

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

; ------------------ Temperory Real Mode ------------------
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
    ; Flip the cr0 to switch back to real mode
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

    ; Lets try to print the CPU Vendor, just a fun late night activity
    ; assert : cpu support cpuid and is 32bit or above
    mov eax, 0x00000000
    cpuid
    mov di, 0x9000
    mov dword [di], ebx 
    mov dword [di + 4], edx 
    mov dword [di + 8], ecx
    mov byte [di + 12], 0
    mov si, di
    call print_string
    call print_new_line

    ; Build the memory map at address 0x8000
    mov di, 0x0600
    call build_memory_map ; Call out function to do memory map
    jc proof_failed       ; Just in case

    ; Print the number of enteries
    mov di, 0x9000
    call number_to_str
    mov si, di
    call print_string
    call print_new_line

    ; We need to load elf files now

    jmp hang

proof_failed:
    mov si, urm_failure
    call print_string
    jmp hang

; ===============================================================
;                  Read-only data & Buffers
; ===============================================================
SECTION .data
some_data db "hello", 0
SECTION .rodata
msg db "Hello Sugat, form Stage 2", 0
a20_enabled_msg db "Enabled A20...", 0
a20_fail_msg db "Bios failed to enable A20 line!!", 0
urm_msg db "Hello from Unreal Mode", 0
urm_failure db "Failed to enable Unreal mode", 0
