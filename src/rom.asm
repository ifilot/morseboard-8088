bits 16

%define UART_BASE      0x20

%define UART_THR       UART_BASE + 0    ; Transmit Holding Register (write)
%define UART_RBR       UART_BASE + 0    ; Receiver Buffer Register (read)
%define UART_DLL       UART_BASE + 0    ; Divisor Latch LSB (when DLAB=1)

%define UART_IER       UART_BASE + 1    ; Interrupt Enable Register
%define UART_DLM       UART_BASE + 1    ; Divisor Latch MSB (when DLAB=1)

%define UART_IIR       UART_BASE + 2    ; Interrupt Identification Register (read)
%define UART_FCR       UART_BASE + 2    ; FIFO Control Register (write)

%define UART_LCR       UART_BASE + 3    ; Line Control Register
%define UART_MCR       UART_BASE + 4    ; Modem Control Register
%define UART_LSR       UART_BASE + 5    ; Line Status Register
%define UART_MSR       UART_BASE + 6    ; Modem Status Register
%define UART_SCR       UART_BASE + 7    ; Scratch Register (optional)

; === Bit definitions
%define LCR_DLAB       0x80
%define LCR_8N1        0x03
%define FCR_ENABLE     0x01
%define FCR_CLEAR_RX   0x02
%define FCR_CLEAR_TX   0x04
%define MCR_RTS        0x02
%define MCR_DTR        0x01
%define MCR_OUT2       0x08
%define LSR_THRE       0x20     ; Transmit Holding Register Empty
%define MSR_CTS        0x10     ; Clear To Send

%define LF             0x0A     ; Line Feed
%define CR             0x0D     ; Carriage Return

; === This code runs at 0x80000 physical address
org 0x80000

; position stack
mov ax, 0x1000
mov ss, ax
mov sp, 0xFFFE

; initialize uart
call init_uart

; set-up ISR
mov ax,0
mov es, ax
mov word [es:0x60 * 4], isr_alt     ; write offset
mov ax, 0x8000                      ; hardcode segment
mov [es:0x60 * 4 + 2], ax

mov ax, [es:0x60 * 4]
out 0x00, al
call delay
mov al,ah
out 0x00, al
call delay

mov ax, [es:0x60 * 4 + 2]
out 0x00, al
call delay
mov al,ah
out 0x00, al
call delay

mov ax, isr_alt
out 0x00, al       ; offset low
call delay
mov al, ah         ; offset high
out 0x00, al
call delay

; Enable interrupts
sti

; send "ready" char
mov al, '@'
call putch

loop:
    mov al, 0xAA
    out 0x00, al
    call delay
    mov al, 0x55
    out 0x00, al
    call delay

jmp loop

;
; 500 ms delay function for the NEC V20, about 
;
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

;
; 500 ms delay function for the NEC V20, about 
;
delay_long:
    mov cx, 2000       ; Outer loop × inner loop = total delay
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

; initialize the UART
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

    ret

; send a single character over the uart, character to be
; sent is set in AL; garbles AH
putch:
    mov ah,al           ; store AL temporarily in AH
    call wait_tx_ready
    call wait_cts
    mov al,ah           ; retrieve AL from AH
    out UART_THR, al
    ret

; wait for TX to be ready
wait_tx_ready:
    in al, UART_LSR     ; overwrites AL!
    test al, LSR_THRE
    jz wait_tx_ready
    ret

; wait for CTS to go low
wait_cts:
    in al, UART_MSR     ; overwrites AL!
    test al, MSR_CTS
    jz wait_cts
    ret

; interrupt service routine for my UART
isr_uart:
    cli
    push ax

    ; check whether this is reached or not
    mov al,0x01
    out 0x00, al

    ; Check why we got the interrupt (not strictly required for simple echo)
    ;in al, UART_IIR
    ;and al, 0x06       ; Bits 1-2 hold reason
    ;cmp al, 0x04       ; 0b100 = Received Data Available
    ;jne .done

    ; Read received char
    in al, UART_RBR

    ; check whether this is reached or not
    mov al,0x02
    out 0x00, al

    ; Echo it back
    call putch

.done:
    ; Send EOI to PIC if needed (not required if you're not using 8259)
    pop ax
    sti
    iret

isr_alt:
    mov al, 0xF0
    out 0x00, al      ; pulse debug line
    call delay
    iret

; === Pad to reset vector at 0xFFFF0
times 0xFFFF0 - 0x80000 - ($ - $$) db 0xFF

; === Reset vector: placed at ROM offset 0x7FFF0
    jmp 0x8000:0x0000     ; this jump hits address 0x80000

; === Pad to 512 KiB total
times 0x80000 - ($ - $$) db 0xFF

