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

; bit definitions
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

; LEDs
%define LEDBASE        0x00

; keyboard buffer
%define KEYBUF         0x0500
%define KEYBUFLPTR     KEYBUF + 256
%define KEYBUFRPTR     KEYBUFLPTR + 1