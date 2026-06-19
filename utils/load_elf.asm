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
ELF_HEAD_OFFSET     equ 0x9200
ELF_MAGIC_SIGNATURE equ 0x464c457f ; 0x7F, 'E', 'L', 'F' but in little endian

; =================================================================  
; CODE SEGMENT: Executable Instructions
; =================================================================
SECTION .text

; =================================================================
; Function    : load_elf32
; Assumptions : CPU is in Unreal Mode, 512B from SECTOR_BUF_SP 
;                           are free
; Input       : AX = lower 2 bytes of target lba where elf sits,
;               BP = upper 2 bytes of target lba
;               DL = drive number
; Output      ; CF = if any error
; =================================================================
load_elf32:
    clc ; Clear the carry flag, no error yet

    ; --- Load first 2 sectors to scratch pad memory
    ; AX and BP taken as argments
    ; DI alread set above
    mov cx, 0x02      ; Read 3 sectors 
    ; DL already taken as input
    call read_sectors ; Call function to read sectors
    jc load_elf32__error_exit
    
    ; Perform checks
    ; verify if the file is elf using magic signature
    cmp dword [di + ELF32H_MAGIC], ELF_MAGIC_SIGNATURE
    jne load_elf32__error_exit
    ; As endianness and class combined just takes only 2 bytes we could use single comparison
    cmp word [di + ELF32H_CLASS], 0x0101 ; 01 for 32bit and 01 for little endian
    jne load_elf32__error_exit
    ; Check for maching or ISA
    cmp word [di + ELF32H_MACHINE], 0x03 ; 03 for x86, 0x3E for amd64
    jne load_elf32__error_exit

    ; Copy data form bouce buffer to header buffer
    mov cx, [di + ELF32H_EHSIZE]
    mov ax, [di + ELF32H_PHENTSIZE]
    mul word [di + ELF32H_PHNUM]
    add cx, ax                   ; CX = Size of elf header + PHTE size * PHTE number
    mov si, di
    mov di, ELF_HEAD_OFFSET
    call memcpy 

    mov cx, [di + ELF32H_PHNUM] ; CX = number of program headers
    mov bp, [di + ELF32H_PHOFF] 
    add bp, di  ; PHOFF is a relative file offset, di is base pointer

    mov ax, 0
loop_pht_entries:
    ; if the entry type is PT_LOAD, print something else something else
    cmp dword [bp + ELF32PH_TYPE], 0x01
    jne elf32phte_nto_load
elf32phte_to_load:
    ; Branch A

    ; Need to load the program here

loop_pht_entries_adv:
    ; Advance BP to the next program header entry
    inc ax
    add bp, [di + ELF32H_PHENTSIZE]
    loop loop_pht_entries

    jmp load_elf32__exit
load_elf32__error_exit:
    stc; set carry flag indicating some error
load_elf32__exit:
    ret

elf32phte_nto_load:
    ; Branch B
    jmp loop_pht_entries_adv

SECTION .rodata
ready_to_load_msg db "Ready to load elf",0
