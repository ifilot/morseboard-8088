bits 16

%define IO00           0x00
%define VERA_BASE      0x40

; VERA register offsets from the Commander X16 register map.
; The board decodes VERA at I/O base 0x40.
%define VERA_ADDR_L    VERA_BASE + 0x00
%define VERA_ADDR_M    VERA_BASE + 0x01
%define VERA_ADDR_H    VERA_BASE + 0x02
%define VERA_DATA0     VERA_BASE + 0x03
%define VERA_CTRL      VERA_BASE + 0x05
%define VERA_DC_VIDEO  VERA_BASE + 0x09
%define VERA_DC_HSCALE VERA_BASE + 0x0A
%define VERA_DC_VSCALE VERA_BASE + 0x0B
%define VERA_DC_BORDER VERA_BASE + 0x0C
%define VERA_L0_CONFIG VERA_BASE + 0x0D
%define VERA_L0_MAP    VERA_BASE + 0x0E
%define VERA_L0_TILE   VERA_BASE + 0x0F
%define VERA_L0_HSC_L  VERA_BASE + 0x10
%define VERA_L0_HSC_H  VERA_BASE + 0x11
%define VERA_L0_VSC_L  VERA_BASE + 0x12
%define VERA_L0_VSC_H  VERA_BASE + 0x13

%define BITMAP_BYTES   38400

; === This code runs at 0x80000 physical address
org 0x80000

; position stack
mov ax, 0x1000
mov ss, ax
mov sp, 0xFFFE

; Let the VERA module/FPGA settle after board reset before register writes.
call delay

; The Arduino driver does this after hardware reset. CTRL bit 7 asks VERA to
; reset/reconfigure internally; the delay gives it time to come back.
mov al, 0x80
out VERA_CTRL, al
call delay

; Select normal VERA register bank: ADDRSEL=0, DCSEL=0.
mov al, 0x00
out VERA_CTRL, al

; Match the known-working Arduino path: 640x480 1bpp bitmap on layer 0.
mov al, 0x80
out VERA_DC_HSCALE, al
out VERA_DC_VSCALE, al

mov al, 0x00
out VERA_DC_BORDER, al

mov al, 0x04
out VERA_L0_CONFIG, al

mov al, 0x00
out VERA_L0_MAP, al

; Bitmap base is VRAM 0x00000. In 1bpp bitmap mode the Arduino driver uses
; TILEBASE = (bitmap_base >> 9) | 0x01.
mov al, 0x01
out VERA_L0_TILE, al

mov al, 0x00
out VERA_L0_HSC_L, al
out VERA_L0_HSC_H, al
out VERA_L0_VSC_L, al
out VERA_L0_VSC_H, al

; Palette entry 0 = black, entry 1 = amber. Palette lives at VRAM 0x1FA00.
mov al, 0x00
out VERA_ADDR_L, al
mov al, 0xFA
out VERA_ADDR_M, al
mov al, 0x11       ; address bit 16 set, DATA0 auto-increment by 1
out VERA_ADDR_H, al
mov al, 0x00       ; color 0 low byte
out VERA_DATA0, al
mov al, 0x00       ; color 0 high byte
out VERA_DATA0, al
mov al, 0x80       ; color 1 low byte: green medium, blue 0
out VERA_DATA0, al
mov al, 0x0F       ; color 1 high byte: red full
out VERA_DATA0, al

; Fill the 1bpp bitmap with foreground pixels. If layer 0 is working, this
; should create a solid amber active display area.
mov al, 0x00
out VERA_ADDR_L, al
out VERA_ADDR_M, al
mov al, 0x10       ; VRAM 0x00000, DATA0 auto-increment by 1
out VERA_ADDR_H, al

mov cx, BITMAP_BYTES
mov dx, VERA_DATA0
mov al, 0xFF
fill_bitmap:
    out dx, al
    loop fill_bitmap

; Turn VGA/RGB output on and enable layer 0.
mov al, 0x11
out VERA_DC_VIDEO, al

; Cycle the VERA border color. If the VERA module, I/O decode, and video output
; are alive, the monitor should show changing colors. The bitmap is filled with
; palette index 1, so changing palette entry 1 changes the whole screen.
xor bl, bl

color_loop:
    xor bh, bh
    shl bx, 1

    ; Point DATA0 at palette entry 1: VRAM 0x1FA02.
    mov al, 0x02
    out VERA_ADDR_L, al
    mov al, 0xFA
    out VERA_ADDR_M, al
    mov al, 0x11       ; address bit 16 set, DATA0 auto-increment by 1
    out VERA_ADDR_H, al

    mov al, [cs:palette_cycle + bx]
    out VERA_DATA0, al
    mov al, [cs:palette_cycle + bx + 1]
    out VERA_DATA0, al

    shr bx, 1

    mov al, bl
    out VERA_DC_BORDER, al

    ; Mirror the current color index on the LED latch too. This tells us the
    ; CPU is still running even if the monitor stays dark.
    out IO00, al

    call delay

    inc bl
    and bl, 0x0F
    jmp color_loop

; VERA 12-bit RGB palette bytes:
; low byte = GGGGBBBB, high byte = ----RRRR.
palette_cycle:
    db 0x00, 0x0F     ; red
    db 0xF0, 0x00     ; green
    db 0x0F, 0x00     ; blue
    db 0xF0, 0x0F     ; yellow
    db 0x0F, 0x0F     ; magenta
    db 0xFF, 0x00     ; cyan
    db 0xFF, 0x0F     ; white
    db 0x80, 0x0F     ; amber
    db 0x08, 0x08     ; purple
    db 0x88, 0x08     ; grey
    db 0x40, 0x0F     ; orange
    db 0x84, 0x00     ; teal
    db 0x04, 0x0F     ; pink-red
    db 0xA0, 0x04     ; soft green
    db 0x0A, 0x04     ; soft blue
    db 0xAA, 0x0A     ; light grey

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

; === Pad to reset vector at 0xFFFF0
times 0xFFFF0 - 0x80000 - ($ - $$) db 0xFF

; === Reset vector: placed at ROM offset 0x7FFF0
    jmp 0x8000:0x0000     ; this jump hits address 0x80000

; === Pad to 512 KiB total
times 0x80000 - ($ - $$) db 0xFF
