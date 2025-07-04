# MorseBoard 8088

Single board computer revolving around the Intel 8088 microprocessor.

# Board lay-out
The 20-pin address bus of the 8088 allows for 1MiB of address space which is
allocated by a lower 512 KiB segment of RAM and an upper 512 KiB segment of ROM.
Multiplexing of the shared address / data pins is handled by 74HCT573 chips.
Serial communication is done using a TL16C550 chip and a MAX232 chip. Using a
74HCT273, 8 LEDs are hooked up as the output of I/O port 0x00. A 7.3728 MHz CAN
oscillator is used both for driving the 8088 as well as for the serial
communication. Note that because of this choice, one needs to use 8088-2 type of
CPUs which allow for this higher clock frequency.

# Design files
The design files for the board are found in `pcb/morseboard-8088`. Source is
found under `src/uartboard`. Assembling is best done using the
[nasm](https://www.nasm.us/) assembler which is freely available via the package
manager under e.g. Linux Ubuntu. A `Makefile` is provided to assist in this
process. To flash the ROM, it is recommended to use the PICO-SST39SF0x0 programmer
as found [in this repository](https://github.com/ifilot/pico-sst39sf0x0-programmer).

# Test board
Besides the "full" board hosting a UART chip, there is also a test board available
under `pcb/cpu-testboard` designed for easy testing of a 8088 processor, especially
since these processor are no longer in production and procurement of these CPUs
from the second hand market does not always yield working chips.