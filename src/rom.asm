bits 16

; === This code runs at 0x80000 physical address
org 0x80000

; position stack
mov ax, 0x1FFF    ; top of 128 KiB RAM
mov ss, ax
mov sp, 0xFFFE    ; stack starts just 2 bytes below top

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

; === Pad to reset vector at 0xFFFF0
times 0xFFFF0 - 0x80000 - ($ - $$) db 0xFF

; === Reset vector: placed at ROM offset 0x7FFF0
    jmp 0x8000:0x0000     ; this jump hits address 0x80000


; === Pad to 512 KiB total
times 0x80000 - ($ - $$) db 0xFF

