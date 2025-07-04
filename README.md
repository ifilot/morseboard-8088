## MorseBoard 8088

**A single-board computer built around the Intel 8088 microprocessor.**

The name **MorseBoard** is a tribute to [Stephen P.
Morse](https://en.wikipedia.org/wiki/Stephen_P._Morse), the lead architect of
the Intel 8086 microprocessor — the foundational design on which the 8088 is
based. His work played a pivotal role in shaping early x86 computing.

## Board Layout

The 8088’s 20-bit address bus allows access to **1 MiB** of addressable memory,
divided into:

- **512 KiB of RAM** in the lower memory segment  
- **512 KiB of ROM** in the upper memory segment  

Address/data multiplexing is handled using **74HCT573 latches**.  
Serial communication is enabled via a **TL16C550 UART** and a **MAX232** level
shifter.

Eight LEDs are connected to **I/O port `0x00`** using a **74HCT273 register**,
providing simple visual output.

A **7.3728 MHz CAN oscillator** is used to drive both the 8088 and the serial
interface. Because of this frequency, you must use the **8088-2** variant, which
supports higher clock rates.

## Design Files

- **PCB layout**: `pcb/morseboard-8088`  
- **Firmware source**: `src/uartboard`  

Assembly is done using the [NASM assembler](https://www.nasm.us/), available via
common Linux package managers (e.g., Ubuntu). A `Makefile` is provided for
convenience.

To flash the ROM, the recommended tool is the [PICO-SST39SF0x0
programmer](https://github.com/ifilot/pico-sst39sf0x0-programmer).

## Test Board

In addition to the full-featured board with UART support, a **CPU test board**
is available under `pcb/cpu-testboard`. This board is designed to validate 8088
chips — particularly useful given the unreliability of some second-hand CPUs,
since they are no longer in production.

## License

### Hardware

The hardware design files for the MorseBoard 8088 are licensed under the  
**CERN Open Hardware License v2 - Strongly Reciprocal (CERN-OHL-S-2.0)**.  
You are free to use, modify, and distribute the hardware under the terms of this
license.  
More info: [CERN-OHL-S-2.0](https://ohwr.org/project/cernohl/wikis/Documents/CERN-OHL-version-2)

### Software

The firmware and software source code is licensed under the  
**GNU General Public License v3.0 (GPLv3)**.  
You are free to use, share, and modify the code as long as derivative works
remain under the same license.  
More info: [GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.html)
