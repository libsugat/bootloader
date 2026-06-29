bits 16

; =================================================================  
; External symbols
; =================================================================  

extern print_string
extern number_to_hex
extern print_new_line
extern read_sectors
extern clear_bytes

extern memcpy
extern memcpy_unreal
extern clear_bytes_unreal

; =================================================================  
; Exported symbols
; =================================================================  

global load_elf32

; ================================================================
; STRUCT DEFINITIONS
; ================================================================
; ----- ELF32 Header Structure Offsets
ELF32H_MAGIC        equ 0      ; 0-3:   0x7F, 'E', 'L', 'F'
ELF32H_CLASS        equ 4      ; 4:     1 = 32-bit, 2 = 64-bit
ELF32H_ENDIAN       equ 5      ; 5:     1 = Little Endian, 2 = Big Endian
ELF32H_VERSION      equ 6      ; 6:     ELF header version
ELF32H_OSABI        equ 7      ; 7:     OS ABI (usually 0 for System V)
                               ; 8-15:  Unused/padding 
ELF32H_TYPE         equ 16     ; 16-17: Object file type (1=reloc, 2=exec, etc.)
ELF32H_MACHINE      equ 18     ; 18-19: Architecture / Instruction set
ELF32H_VERSION_EXT  equ 20     ; 20-23: ELF Version (currently 1)
ELF32H_ENTRY        equ 24     ; 24-27: Program entry memory offset
ELF32H_PHOFF        equ 28     ; 28-31: Program header table file offset
ELF32H_SHOFF        equ 32     ; 32-35: Section header table file offset
ELF32H_FLAGS        equ 36     ; 36-39: Processor-specific flags
ELF32H_EHSIZE       equ 40     ; 40-41: ELF Header size in bytes
ELF32H_PHENTSIZE    equ 42     ; 42-43: Size of an entry in program header table
ELF32H_PHNUM        equ 44     ; 44-45: Number of entries in program header table
ELF32H_SHENTSIZE    equ 46     ; 46-47: Size of an entry in section header table
ELF32H_SHNUM        equ 48     ; 48-49: Number of entries in section header table
ELF32H_SHSTRNDX     equ 50     ; 50-51: Section header string table index
ELF32H_SIZE         equ 52

; ----- ELF32 Program Header Table Entry Structure Offsets
ELF32PH_TYPE        equ 0x00   ; 0x00: Segment type
ELF32PH_OFFSET      equ 0x04   ; 0x04: Segment file offset
ELF32PH_VADDR       equ 0x08   ; 0x08: Segment virtual address
ELF32PH_PADDR       equ 0x0C   ; 0x0C: Segment physical address
ELF32PH_FILESZ      equ 0x10   ; 0x10: Size of segment in file
ELF32PH_MEMSZ       equ 0x14   ; 0x14: Size of segment in memory
ELF32PH_FLAGS       equ 0x18   ; 0x18: Segment flags (Read/Write/Execute)
ELF32PH_ALIGN       equ 0x1C   ; 0x1C: Segment alignment
ELF32PH_SIZE        equ 0x20

; ----- Useful memory addresses ----
BOUNCE_BUFFER_OFFSET     equ 0xd000
ELF_HEAD_OFFSET     equ 0x9200
ELF_MAGIC_SIGNATURE equ 0x464c457f ; 0x7F, 'E', 'L', 'F' but in little endian

; =================================================================  
; CODE SEGMENT: Executable Instructions
; =================================================================
SECTION .text

; =================================================================
; Function    : load_elf32
; Assumptions : CPU is in Unreal Mode, 512B from ELF_HEAD_OFFSET 
;                           are free
; Input       : EAX = lower 4 bytes of target lba where elf sits,
;               EBP = upper 4 bytes of target lba
;               DL = drive number
; Output      ; CF = if any error, 
;               EAX = Address of entry point of the loaded elf
; =================================================================
load_elf32:
    clc ; Clear the carry flag, no error yet

    ; Save the LBA, where elf starts(passed as argument)
    mov dword [elf_lba_offset], eax
    mov dword [elf_lba_offset + 4], ebp
    mov byte [drive_with_elf], dl

    ; --- Load first 2 sectors to scratch pad memory
    ; AX and BP taken as argments
    ; DI alread set above
    mov cx, 0x02      ; Read 2 sectors 
    mov di, BOUNCE_BUFFER_OFFSET
    ; DL already taken as input
    call read_sectors ; Call function to read sectors
    jc .exit

    
    ; Perform checks
    ; verify if the file is elf using magic signature
    cmp dword [di + ELF32H_MAGIC], ELF_MAGIC_SIGNATURE
    jne .error_exit
    ; As endianness and class combined just takes only 2 bytes we could use single comparison
    cmp word [di + ELF32H_CLASS], 0x0101 ; 01 for 32bit and 01 for little endian
    jne .error_exit
    ; Check for maching or ISA
    cmp word [di + ELF32H_MACHINE], 0x03 ; 03 for x86, 0x3E for amd64
    jne .error_exit
    

    ; Copy data form bouce buffer to header buffer
    mov ecx, [di + ELF32H_EHSIZE]
    xor eax, eax
    mov ax, [di + ELF32H_PHENTSIZE]
    mul word [di + ELF32H_PHNUM]
    add ecx, eax                   ; CX = Size of elf header + PHTE size * PHTE number
    xor esi, esi
    mov si, di
    mov edi, ELF_HEAD_OFFSET
    call memcpy

    mov edi, ELF_HEAD_OFFSET
    xor ecx, ecx
    mov cx, [edi + ELF32H_PHNUM] ; CX = number of program headers
    mov bp, [edi + ELF32H_PHOFF] 
    add bp, di  ; PHOFF is a relative file offset, di is base pointer


    mov ax, 0
.loop_pht_entries:
    ; if the entry type is PT_LOAD, print something else something else
    cmp dword [bp + ELF32PH_TYPE], 0x01
    jne .elf32phte_skip
.elf32phte_to_load:
    ; Branch A: If ph_type == PT_LOAD
    pushad

    ; Extract data to and free up ebp for use
    mov word [current_program_header_offset], bp
    mov eax, [bp + ELF32PH_OFFSET]
    mov ebx, eax                    ; Alocating ABX as coursor of bounce buffer
    and ebx, 0x01ff                 ; the the place relative to active sector of loading, ebx % 512
    mov ecx, [bp + ELF32PH_FILESZ]  ; Bytes to load in in memory
    mov edi, [bp + ELF32PH_PADDR]   ; This is the place where it is expected to load elf segment
    ; NOTE: Do not update edi, or even try to use it unless wrapped with push and pop edi
    ;       to keep a consistant cursor to destination

    ; ------------ Load data from first unaligned sector -----------
    ;   Load the active sector to bounce buffer
    pushad
    xor ebp, ebp
    shr eax, 9 ; divide by 512
    add eax, [elf_lba_offset]
    adc ebp, [elf_lba_offset + 4]
    mov edi, BOUNCE_BUFFER_OFFSET
    mov cx, 0x01
    xor edx, edx
    mov dl, [drive_with_elf]
    call read_sectors
    jnc .no_error_sector_read
    ; If error fix the stack alignment and just jump to exit with error
    popad
    popad
    jmp .error_exit
.no_error_sector_read:
    popad ; restore the cpu state before loading the fist sector to bounce buffer

    ; Calculate the number of Bytes, that are available 
    ; after the calculated offset form the sector start
    ; and store in ebp
    mov ebp, eax        ; ecx = file_offset (eax is preserved!)
    and ebp, 511        ; ecx = file_offset % 512 (bytes used in current sector)
    mov esi, ebp        ; esi = loadable_data_offset relative to sector start
    not ebp             ; ecx = -ecx - 1
    lea ebp, [ebx + 512]; ecx = (-ecx - 1) + 513  =>  512 - ecx

    push ecx
    ; ECX = Minimum(ph_filesz(ecx), bytes loadeable from the current sector)
    cmp ecx, ebp
    cmovg ecx, ebp ; if ecx > ebp : ecx = ebp
    mov edx, ecx   ; Save the Number of bytes we are loading, will be used to update values
    add esi, BOUNCE_BUFFER_OFFSET
    ; edi already loaded
    call memcpy_unreal
    pop ecx
    ; ------ Loading first sector done  ------


    ; Update, number of bytes to load, the file_offset and calculate he total sectors to load
    add eax, edx
    sub ecx, edx
    jz .read_and_load_part_done
    mov edx, ecx
    add edx, 511
    shr edx, 9 ; Divide by 512

    ; ----- Load data from consiqutive sectors to the designated memory 
    ; Use edx as counter of remaining segments
.segment_sector_loading_loop:
    ; Load the sector to Bounce buffer
    push eax
    push edx
    push ecx
    push edi
    xor ebp, ebp
    shr eax, 9 ; Calculate the the sector number relative to file start
    add eax, [elf_lba_offset]     ; Convert the sector number relative to file start to LBA 
    adc ebp, [elf_lba_offset + 4] ; Calculate the upper 4 bytes of LBA
    mov edi, BOUNCE_BUFFER_OFFSET
    mov cx, 0x01
    xor edx, edx
    mov dl, [drive_with_elf]
    call read_sectors
    pop edi
    pop ecx
    pop edx
    pop eax

    ; Copy the required data from bounce buffer to its exact location
    push ecx
    ; calculate the number of bytes to move
    ; ecx = min(ecx, 0x200)
    mov ebx, 0x200
    cmp ecx, ebx
    cmovg ecx, ebx
    mov ebx, ecx    ; Save the the number of bytes being moved
    mov esi, 0xd000
    ; EDI is already set
    call memcpy_unreal
    pop ecx

    ; Update file offset, number of bytes
    sub ecx, ebx
    add eax, ebx
    dec edx ; Decrement the number of sectors remaining
    jnz .segment_sector_loading_loop

.read_and_load_part_done:

    ; Loading ph_filesz and ph_memsize fomr the cache
    mov bp, [current_program_header_offset]
    mov ecx, [bp + ELF32PH_MEMSZ]
    ; Calculate the uninitialized data bytes to be zerod/cleared
    sub ecx, [bp + ELF32PH_FILESZ]
    call clear_bytes_unreal

.elf32phte_to_load__done:
    
    popad
.loop_pht_entries_adv:
    ; Advance BP to the next program header entry
    inc ax
    add bp, [di + ELF32H_PHENTSIZE]
    dec ecx              ; Decrement loop counter manually
    jnz .loop_pht_entries
    ; loop .loop_pht_entries ; Jump if ecx != 0

    ; Return the memory address of kernel start
    mov eax, [di + ELF32H_ENTRY]

    jmp .exit
.error_exit:
    stc; set carry flag indicating some error
.exit:
    ret

.elf32phte_skip:
    ; Branch B: If ph_type != PT_LOAD
    jmp .loop_pht_entries_adv

SECTION .data
drive_with_elf db 0x0
elf_lba_offset dq 0x0
current_program_header_offset dw 0x0

SECTION .rodata
ready_to_load_msg db "Ready to load elf",0
