bits 16

%define IO00 0x00
%define IO03 0x60

; === This code runs at 0x80000 physical address.
org 0x80000

start:
cli

mov ax, 0x1000
mov ss, ax
mov sp, 0xFFFE

blink_loop:
    in al, IO03
    out IO00, al
    call delay

    mov al, 0x00
    out IO00, al
    call delay

    jmp blink_loop

delay:
    mov cx, 200
.outer_loop:
    mov dx, 250
.inner_loop:
    nop
    nop
    nop
    nop
    dec dx
    jnz .inner_loop
    loop .outer_loop
    ret

; === Pad to reset vector at 0xFFFF0.
times 0xFFFF0 - 0x80000 - ($ - $$) db 0xFF

; === Reset vector: placed at ROM offset 0x7FFF0.
    jmp 0x8000:0x0000

; === Pad to 512 KiB total.
times 0x80000 - ($ - $$) db 0xFF
