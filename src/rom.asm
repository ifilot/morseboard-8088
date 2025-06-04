bits 16

; === This code runs at 0x80000 physical address
org 0x80000

; position stack
mov ax, 0x1FFF    ; top of 128 KiB RAM
mov ss, ax
mov sp, 0xFFFE    ; stack starts just 2 bytes below top

loop:
    call init_uart
    call send_char

    mov al, 0xAA
    out 0x00, al
    call delay
    mov al, 0x55
    out 0x00, al
    call delay
    call send_char

jmp loop

;
; 500 ms delay function for the NEC V20, about 
;
delay:
    mov cx, 200       ; Outer loop × inner loop = total delay
outer_loop:
    mov dx, 250       ; Inner loop count (fine-tuned)
inner_loop:
    nop               ; 1 cycle
    nop               ; 1 cycle
    nop               ; 1 cycle
    nop               ; 1 cycle
    dec dx            ; ~3 cycles
    jnz inner_loop    ; ~16 cycles when taken
    loop outer_loop   ; ~17 cycles when taken
    ret

init_uart:
    ; Set DLAB = 1 to access divisor registers
    mov dx, 0x23      ; Line Control Register (LCR)
    mov al, 0x80      ; Set DLAB=1 (bit 7)
    out dx, al

    ; Set divisor low byte (DLL = 4)
    mov dx, 0x20      ; DLL register (with DLAB=1)
    mov al, 4         ; 7.3728E6 / (115200 * 16) = 4
    out dx, al

    ; Set divisor high byte (DLM = 0)
    mov dx, 0x21      ; DLM register (with DLAB=1)
    mov al, 0
    out dx, al

    ; disable DLAB and set nr bits, parity, etc
    mov dx, 0x23      ; LCR
    mov al, 0x03      ; 8 data bits, 1 stop bit, no parity, DLAB=0
    out dx, al

    ; enable FIFO
    mov dx, 0x22      ; FCR
    mov al, 0x07      ; Enable FIFO, clear TX/RX FIFOs
    out dx, al

    ; set modem control signals
    mov dx, 0x24      ; MCR
    mov al, 0x0B      ; DTR, RTS, OUT2 set (enable IRQs if used)
    out dx, al

    ret

send_char:
    ; transmit a character
    wait_tx:
        mov dx, 0x25      ; LSR
        in al, dx
        test al, 0x20     ; THR empty?
        jz wait_tx

    ; Send a character
    mov dx, 0x20      ; THR (Transmit Holding Register)
    mov al, 'A'       ; Character to transmit
    out dx, al

    ret

; === Pad to reset vector at 0xFFFF0
times 0xFFFF0 - 0x80000 - ($ - $$) db 0xFF

; === Reset vector: placed at ROM offset 0x7FFF0
    jmp 0x8000:0x0000     ; this jump hits address 0x80000


; === Pad to 512 KiB total
times 0x80000 - ($ - $$) db 0xFF

