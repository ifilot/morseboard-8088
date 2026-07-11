# ATmega328P Controller Firmware

This directory contains starter firmware for the MorseBoard 8088 controller
MCU. It builds a raw AVR image for an ATmega328P.

## Install the Linux toolchain

On Debian or Ubuntu:

```bash
sudo apt update
sudo apt install make gcc-avr avr-libc binutils-avr avrdude
```

On Fedora:

```bash
sudo dnf install make avr-gcc avr-libc avr-binutils avrdude
```

On Arch Linux:

```bash
sudo pacman -S make avr-gcc avr-libc avr-binutils avrdude
```

What each package does:

- `gcc-avr` / `avr-gcc`: cross-compiler that emits AVR machine code.
- `avr-libc`: AVR headers and C runtime, including `<avr/io.h>` and interrupt
  vector support.
- `binutils-avr`: AVR linker, `avr-objcopy`, `avr-objdump`, and related tools.
- `make`: runs the build recipe in `Makefile`.
- `avrdude`: uploads the compiled firmware to the MCU through an ISP or serial
  programmer.

## Build

```bash
cd src/controller
make
```

The default build assumes:

- MCU: `atmega328p`
- CPU clock: `16000000UL`
- output name: `controller`

Generated files are placed in `build/`:

- `controller.elf`: linked firmware with symbols.
- `controller.hex`: Intel HEX file, normally used by programmers.
- `controller.bin`: raw binary image.

Override build settings on the command line when needed:

```bash
make F_CPU=7372800UL
make MCU=atmega328p F_CPU=16000000UL
```

## Flash

For a USBasp connected to the ATmega328P ISP header:

```bash
make flash PROGRAMMER=usbasp
```

For an Arduino-as-ISP style setup:

```bash
make flash PROGRAMMER=avrisp PORT=/dev/ttyACM0 BAUD=19200
```

You can also call `avrdude` directly:

```bash
avrdude -p atmega328p -c usbasp -U flash:w:build/controller.hex:i
```

## Fuses

The Makefile includes an example `make fuses` target for a 16 MHz external
crystal or clock:

```bash
make fuses PROGRAMMER=usbasp
```

Fuse settings can make the chip appear dead if they select a clock source that
is not present. Confirm your clock hardware and desired brown-out behavior
before writing them. `PB6/PB7` are `XTAL1/XTAL2` in the current schematic, so
the external crystal is expected to own those pins.

## Firmware shape

`include/board.h` contains the pin map pulled from the controller schematic.
`src/main.c` currently provides the board reset policy plus the first keyboard
interrupt-controller path:

- assert the board reset line immediately by driving `RES` low on `PB0`;
- press `ON_BTN` to keep reset asserted for 0.5 s, then release the board;
- hold `ON_BTN` for 3 s to assert reset again;
- press `RESET_BTN` to assert a 0.2 s reset pulse.
- receive PS/2 Set-2 scan codes on `KB_CLK`/`KB_DATA`;
- ignore release/break codes and extended keys for now;
- translate common make codes to lowercase ASCII;
- assert active-high `INTR` when one ASCII byte is pending;
- provide interrupt vector `0x20` during `~INTA`;
- provide the pending ASCII byte during an `IO03` read, decoded by the board as
  I/O `0x60`-`0x7F`;
- pre-drive `CD0..CD7` while a key is pending, relying on the 74HCT245 to place
  the byte on AD0..AD7 only while `~INTA` or `~IO03` is active.

This is deliberately a one-byte test path. A later version should add a small
keyboard queue, shift/caps handling, and richer interrupt-source arbitration.
