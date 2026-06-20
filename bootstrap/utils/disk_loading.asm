bits 16
extern clear_bytes

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------
global read_sectors

; =================================================================  
; CODE SEGMENT: Executable Instructions
; =================================================================

SECTION .text
; =============================================================================
; Function: read_sectors
; Input:    EAX = lower 4 bytes of 64 bit target lba
;           EBP = upper 4 bytes of target lba
;           DI = Destination buffer pointer,
;           CX = Number of sectors to read
;           DL = drive number
;
; Output:   CF (Carry Flag), as success indicator
; Assumeption: 16B are free starting at 0x7bf0
; =============================================================================
read_sectors:
    push bx
    ; Clear the memory for DAP
    push cx
    push di
    mov bx, DAP_ADDRESS ; Clear form address DAP_ADDRESS 
    mov di, bx          ; 
    mov cx, 0x10        ;
    call clear_bytes    ;
    pop di
    pop cx

    ; Build the DAP
    mov byte [bx], 0x10                     ; The size of DAP (16 bytes)
    mov word [bx + DAP_DEST_OFF], di        ; destination address of the buffer
    mov word [bx + DAP_SECTORS_OFF], cx     ; Number of sectors to read
    mov dword [bx + DAP_SLBA_OFF], eax        ; LBA bits 0-15
    mov dword [bx + DAP_SLBA_OFF + 4], ebp    ; LBA bits 16-31

    mov ah, 0x42        ; Extended read, disk read
    mov si, DAP_ADDRESS ; Set the address of DAP
    int 0x13            ; Call Bios
    
    pop bx
    ret

; ===============================================================
;      This sections holds reading and writing data
; ===============================================================
SECTION .data align=4   ; writeable data 
    DAP_ADDRESS equ 0x7bf0
    DAP_SECTORS_OFF equ 2
    DAP_DEST_OFF equ 4
    DAP_SLBA_OFF equ 8
