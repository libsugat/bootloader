bits 16
extern clear_bytes

; ------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------
global read_sectors

SECTION .text
; =============================================================================
; Function: read_sectors
; Input:    AX = lower 2 bytes of 64 bit target lba
;           DI = Destination buffer pointer,
;           BP = drive number,
;           CX = Number of sectors to read
;
; Output:   CF (Carry Flag), as success indicator
; Assumeption: 16B are free starting at 0x7bf1
; =============================================================================
read_sectors:
    push bx
    ; Clear the memory for DAP
    push cx
    push di
    mov bx, DAP_ADDRESS
    mov di, bx
    mov cx, 0x10
    call clear_bytes
    pop di
    pop cx

    ; Build the DAP
    mov byte [bx], 0x10                     ; The size of DAP (16 bytes)
    mov word [bx + DAP_DEST_OFF], di        ; destination address of the buffer
    mov word [bx + DAP_SECTORS_OFF], cx     ; Number of sectors to read
    mov word [bx + DAP_SLBA_OFF], ax        ; LBA bits 0-15
    mov word [bx + DAP_SLBA_OFF + 2], bp    ; LBA bits 16-31

    mov ah, 0x42        ; Extended read, disk read
    mov si, DAP_ADDRESS ; Set the address of DAP
    int 0x13            ; Call Bios
    
    pop bx
    ret

; ===============================================================
;      This sections holds reading and writing data
; ===============================================================
SECTION .data align=4   ; writeable data 
    DAP_ADDRESS equ 0x7bf1
    DAP_SECTORS_OFF equ 2
    DAP_DEST_OFF equ 4
    DAP_SLBA_OFF equ 8
