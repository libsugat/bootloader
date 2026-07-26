bits 16

; =================================================================  
; External symbols
; =================================================================  

; Utility Functions from Sector 1 (bootstrap)
extern print_string
extern print_new_line
extern number_to_str
extern read_sectors

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
extern load_elf32
; =================================================================  
; Exported symbols
; =================================================================  

global _start

; =================================================================  
; CODE SEGMENT: Executable Instructions
; =================================================================
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
    mov si, urm_failure   ; If error, put the error message
    jne failed    ; jump will not happen if we are in unreal mode

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

    ; Build the memory map at address 0x0600
    mov di, 0x0600
    call build_memory_map ; Call out function to do memory map
    mov si, mm_failure    ; If error, put the error message
    jc failed       ; Just in case

    ; We need to load elf files now
    mov dl, [BOOT_DRIVE]        ; Read form boot drive
    mov eax, 0x04
    xor ebp, ebp          
    call load_elf32       ; Call the loader
    mov si, elf_load_failure    ; If error, put the error message
    jc failed            ; If CF, then jump print message and end
    
    mov dword [kernel_start_ptr], eax

    mov si, sign_off_string
    call print_string
    call print_new_line

    ; Inform BIOS of target processor mode
    xor bx, bx
    mov ax, 0xec00
    mov bl, 0x01 ; 1 = protected mode
    int 0x15     ; start service call
    ; We will simply ignore the the output status, because some bios does not implement this
    ; This is done specifically to so that motherboard can update its SMM


    ; Time for jump
    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    jmp 0x08:pmode_no_ret

    jmp hang

failed:
    call print_string ; Print the error message
    xor si, si
    jmp hang

bits 32
pmode_no_ret:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov esp, 0x7000    
    mov ebp, esp


    ; Below code is there because xv6 expects SSE Enabled
    ; Proper way to do this is to query all capabilities and enable them
    ; in MSR register
    ; --- Enable SSE Instructions to prevent #UD ---
    mov eax, cr0
    and ax, 0xFFFB      ; Clear CR0.EM (bit 2)
    or ax, 0x0002       ; Set CR0.MP (bit 1)
    mov cr0, eax

    mov eax, cr4
    or ax, 0x0600       ; Set CR4.OSFXSR (bit 9) and CR4.OSXMMEXCPT (bit 10)
    mov cr4, eax
    ; ----------------------------------------------


    mov eax, [kernel_start_ptr]
    jmp eax

; ===============================================================
;                  Read-only data & Buffers
; ===============================================================
SECTION .data
kernel_start_ptr dd 0x0

SECTION .rodata
msg db "Hello Sugat, from Stage 2", 0
a20_enabled_msg db "Enabled A20...", 0
a20_fail_msg db "Bios failed to enable A20 line!!", 0
urm_msg db "Hello from Unreal Mode", 0
urm_failure db "Failed to enable Unreal mode", 0
mm_failure db "Failed to create memory map", 0
elf_load_failure db "Failed to load ELF", 0
sign_off_string db "Hey I am done my job. Aab tumhere haath main system, kernel!!!", 0
