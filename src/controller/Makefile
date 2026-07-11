# MorseBoard 8088 ATmega328P controller firmware.

TARGET := controller
MCU := atmega328p
F_CPU := 16000000UL

BUILD_DIR := build
SRC_DIR := src
INC_DIR := include

CC := avr-gcc
OBJCOPY := avr-objcopy
OBJDUMP := avr-objdump
SIZE := avr-size
AVRDUDE := avrdude

PROGRAMMER ?= usbasp
PORT ?=
BAUD ?= 115200

CPPFLAGS := -DF_CPU=$(F_CPU) -I$(INC_DIR)
CFLAGS := -std=gnu11 -Wall -Wextra -Werror -Os -mmcu=$(MCU) -ffunction-sections -fdata-sections
LDFLAGS := -mmcu=$(MCU) -Wl,--gc-sections

SOURCES := $(wildcard $(SRC_DIR)/*.c)
OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SOURCES))

.PHONY: all clean flash fuses size disasm

all: $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin size

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@

$(BUILD_DIR)/$(TARGET).hex: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) -O binary -R .eeprom $< $@

size: $(BUILD_DIR)/$(TARGET).elf
	$(SIZE) --mcu=$(MCU) -C $<

disasm: $(BUILD_DIR)/$(TARGET).elf
	$(OBJDUMP) -d -S $< > $(BUILD_DIR)/$(TARGET).lst

flash: $(BUILD_DIR)/$(TARGET).hex
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) $(if $(PORT),-P $(PORT),) $(if $(BAUD),-b $(BAUD),) -U flash:w:$<:i

# Example 16 MHz full-swing crystal/clock fuse values for ATmega328P.
# Check your oscillator, pin use, brown-out, and bootloader needs first.
# PB6/PB7 are XTAL1/XTAL2 when these fuses select an external clock.
fuses:
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) $(if $(PORT),-P $(PORT),) -U lfuse:w:0xff:m -U hfuse:w:0xd9:m -U efuse:w:0xff:m

clean:
	rm -rf $(BUILD_DIR)
