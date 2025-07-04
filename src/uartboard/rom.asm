;------------------------------------------------------------------------------
; MORSEBOARD 8088 ROM
;------------------------------------------------------------------------------

bits 16             ; assemble for 8086/8088
org 0x80000         ; upper 512 KiB (ROM)

; include constants for UART, characters, etc.
%include "constants.inc"

;------------------------------------------------------------------------------
; boot routine
;------------------------------------------------------------------------------
boot:
    ; set-up stack
    mov ax, 0x1000
    mov ss, ax
    mov sp, 0xFFFE

    ; initialize system
    call init

    jmp loop

hw:
    db "Hello World!",0

;------------------------------------------------------------------------------
; Main loop with menu and input handling
;------------------------------------------------------------------------------
loop:
    call show_menu
.wait_key:
    mov al, [KEYBUFRPTR]
    mov ah, [KEYBUFLPTR]
    cmp ah, al              ; check if there are any new keypresses in buffer
    je .wait_key            ; if not, check again

    mov si, KEYBUF          ; load keybuffer location
    xor bx, bx
    mov bl, [KEYBUFLPTR]
    add si, bx              ; set pointer
    mov al, [si]            ; read from pointer
    inc bl
    mov [KEYBUFLPTR], bl    ; update keybuffer

    ; Check input
    cmp al, '1'
    je do_strobe
    cmp al, '2'
    je do_pingpong
    jmp .wait_key           ; next key

;------------------------------------------------------------------------------
; Call to 'strobe' routine
;------------------------------------------------------------------------------
do_strobe:
    call strobe
    jmp loop

;------------------------------------------------------------------------------
; Call to ping-pong routine
;------------------------------------------------------------------------------
do_pingpong:
    call pingpong
    jmp loop

;------------------------------------------------------------------------------
; Show selection menu to the user
;------------------------------------------------------------------------------
show_menu:
    mov ax, 0x8000
    mov ds, ax
    mov dx,hw
    mov dx, menu_text
    call puts
    xor ax, ax
    mov ds, ax
    ret

menu_text: 
    db $0D, $0A
    db 'Menu:', $0D, $0A
    db '1. Strobe LEDs', $0D, $0A
    db '2. Ping-pong LEDs', $0D, $0A
    db 'Select option: ', 0

;------------------------------------------------------------------------------
; Initialize system
;------------------------------------------------------------------------------
init:
    call init_uart      ; universal asynchronous serial communication
    call init_ivt       ; interrupt vector table

    mov al, 0x00        ; ensure LEDs are off
    out 0x00, al

    sti                 ; enable interrupts

    xor ax, ax          ; reset AX
    mov ds, ax          ; reset DS
    ret

;------------------------------------------------------------------------------
; small delay function
;
; GARBLES: CX, DX
;------------------------------------------------------------------------------
delay:
    mov cx, 200       ; Outer loop × inner loop = total delay
.outer_loop:
    mov dx, 250       ; Inner loop count (fine-tuned)
.inner_loop:
    nop               ; 1 cycle
    nop               ; 1 cycle
    nop               ; 1 cycle
    nop               ; 1 cycle
    dec dx            ; ~3 cycles
    jnz .inner_loop    ; ~16 cycles when taken
    loop .outer_loop   ; ~17 cycles when taken
    ret

;------------------------------------------------------------------------------
; initialize the UART
;
; GARBLES: AX
;------------------------------------------------------------------------------
init_uart:
    ; Enable DLAB to access divisor registers
    mov al, LCR_DLAB
    out UART_LCR, al

    ; Set baud rate divisor: 115200 baud = divisor 4
    mov al, 4
    out UART_DLL, al      ; LSB
    mov al, 0
    out UART_DLM, al      ; MSB

    ; Disable DLAB, set 8N1 (8 data bits, no parity, 1 stop bit)
    mov al, LCR_8N1
    out UART_LCR, al

    ; Enable FIFO, clear TX and RX FIFOs
    mov al, FCR_ENABLE | FCR_CLEAR_RX | FCR_CLEAR_TX
    out UART_FCR, al

    ; Enable Received Data Available interrupt
    mov al, 0x01
    out UART_IER, al

    ; Set modem control: DTR, RTS, OUT2
    mov al, MCR_DTR | MCR_RTS | MCR_OUT2
    out UART_MCR, al

    ; initialize keyboard buffer
    xor ax, ax
    mov [KEYBUFLPTR], al
    mov [KEYBUFRPTR], al

    ret

;------------------------------------------------------------------------------
; Initialize the interrupt vector table, needed to receive chars over UART
;
; GARBLESS ES, AX
;------------------------------------------------------------------------------
init_ivt:
    mov ax,0
    mov es, ax
    mov ax, isr_uart
    mov word [es:0x60 * 4], ax          ; write offset
    mov ax, 0x8000                      ; write segment
    mov [es:0x60 * 4 + 2], ax
    ret

;------------------------------------------------------------------------------
; PUTCH ROUTINE - send a single character over the uart, character to be
; sent is set in AL; conserves AH
;
; GARBLES: AL
;------------------------------------------------------------------------------
putch:
    push ax
    call wait_tx_ready
    call wait_cts
    mov al,ah           ; retrieve AL from AH
    pop ax
    out UART_THR, al
    ret

;------------------------------------------------------------------------------
; PUTS ROUTINE - print a null-terminated string from address in DX
; take care that DS is set appropriately
;
; GARBLES: nothing
;------------------------------------------------------------------------------
puts:
    push ax
    push dx
    push si
    mov si, dx         ; move pointer to SI
.next_char:
    lodsb              ; load byte at [SI] into AL, increment SI
    cmp al, 0
    je .done
    call putch
    jmp .next_char
.done:
    pop si
    pop dx
    pop ax
    ret

;------------------------------------------------------------------------------
; WAIT_TX_READY ROUTINE - wait for TX to be ready before sending character
;
; Garbles: AL
;------------------------------------------------------------------------------
wait_tx_ready:
    in al, UART_LSR
    test al, LSR_THRE
    jz wait_tx_ready
    ret

;------------------------------------------------------------------------------
; WAIT_CTS - wait for /CTS line to go low before sending character
;
; Garbles: AL
;------------------------------------------------------------------------------
wait_cts:
    in al, UART_MSR     ; overwrites AL!
    test al, MSR_CTS
    jz wait_cts
    ret

;------------------------------------------------------------------------------
; interrupt service routine for the UART
;
; Conserves all registers
;------------------------------------------------------------------------------
isr_uart:
    cli
    push ax
    push bx

    ; Check why we got the interrupt (not strictly required for simple echo)
    in al, UART_IIR
    and al, 0x06            ; Bits 1-2 hold reason
    cmp al, 0x04            ; 0b100 = Received Data Available
    jne .done

    in al, UART_RBR         ; grab byte
    mov si, KEYBUF          ; grab current keybuf position
    xor bx,bx               ; reset BX
    mov bl, [KEYBUFRPTR]    ; load offset
    add si, bx              ; increment index
    mov [si], al            ; store byte
    inc bl                  ; increment pointer
    mov [KEYBUFRPTR], bl    ; store pointer

.done:
    pop bx
    pop ax
    sti
    iret

;------------------------------------------------------------------------------
; PUTHEX16 ROUTINE - Print 16-bit word in AX as 4-digit hex digits
;
; Conserves all registers
;------------------------------------------------------------------------------
puthex16:
    push ax           ; Save AX

    mov al, ah        ; Output high byte
    call puthex       ; Print high byte as hex

    pop ax
    call puthex       ; Print low byte as hex

    ret

;------------------------------------------------------------------------------
; PUTHEX ROUTINE: write 8-bit value in AL as 2-digit hex value
;
; Conserves all registers
;------------------------------------------------------------------------------
puthex:
    push ax           ; Save AX since we will be modifying it

    mov ah, al        ; Copy value to AH so we can extract nibbles

    shr al, 4         ; Get high nibble into AL
    call hexnibble    ; Convert to ASCII
    call putch        ; Print high nibble

    mov al, ah        ; Restore original value into AL
    and al, 0Fh       ; Mask out high nibble, keep low nibble
    call hexnibble    ; Convert to ASCII
    call putch        ; Print low nibble

    pop ax            ; Restore AX
    ret

;------------------------------------------------------------------------------
; NEWLINE ROUTINE - print newline character
;
; Garbles: AL
;------------------------------------------------------------------------------
newline:
    mov al, CR
    call putch
    mov al, LF
    call putch
    ret

;------------------------------------------------------------------------------
; HEXNIBBLE ROUTINE - Converts nibble in AL (0-15) to ASCII ('0'-'9', 'A'-'F')
;------------------------------------------------------------------------------
hexnibble:
    cmp al, 9
    jbe .hex_is_digit
    add al, 7         ; Adjust for 'A'-'F'
.hex_is_digit:
    add al, '0'       ; Convert to ASCII
    ret

;------------------------------------------------------------------------------
; STROBE ROUTINE - sequentially turn on all the LEDs
;
; Garbles: AL, CX
;------------------------------------------------------------------------------
strobe:
    mov cx, 8          ; 8 LEDs / 8 steps
    mov al, 00000001b  ; Start with the first LED on (bit 0)

strobe_loop:
    out 0x00, al       ; Output to the LED port
    push cx
    call delay         ; Call your delay function, garbles cx
    pop cx
    shl al, 1          ; Shift left to move to next LED
    loop strobe_loop   ; Repeat 8 times
    ret

;------------------------------------------------------------------------------
; PINGPONG ROUTINE - LED moves left to right, then right to left
;
; Garbles: AL, BL, CX, DX
;------------------------------------------------------------------------------
pingpong:
    mov al, 00000001b     ; Start with bit 0 on
    mov bl, 1             ; Direction: 1 = left, 0 = right
    mov cx, 15            ; 7 left + 1 mid + 7 right = 15 steps

pingpong_loop:
    out 0x00, al
    push cx
    call delay
    pop cx

    cmp bl, 1
    je .go_left

.go_right:
    shr al, 1
    cmp al, 00000001b     ; If at far right, switch to left
    jne .continue
    mov bl, 1
    jmp .continue

.go_left:
    shl al, 1
    cmp al, 10000000b     ; If at far left, switch to right
    jne .continue
    mov bl, 0

.continue:
    loop pingpong_loop
    ret

;------------------------------------------------------------------------------
; PADDING AND START VECTOR
;
; Fills unused memory space with 0xFF to ensure NOR flash ROM can be
; flashed quickly.
;------------------------------------------------------------------------------
    times 0xFFFF0 - 0x80000 - ($ - $$) db 0xFF
    jmp 0x8000:0x0000                           ; this jump hits address 0x80000
    times 0x80000 - ($ - $$) db 0xFF