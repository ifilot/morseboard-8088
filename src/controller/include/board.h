#ifndef MORSEBOARD_CONTROLLER_BOARD_H
#define MORSEBOARD_CONTROLLER_BOARD_H

#include <avr/io.h>
#include <stdbool.h>
#include <stdint.h>

/*
 * Pin map from the controller schematic.
 *
 * RES is active high from the controller's point of view: the board is held in
 * reset by the external pull-down until firmware drives PB0 high.
 */

#define MB_PIN_CD0_PORT PORTC
#define MB_PIN_CD0_DDR DDRC
#define MB_PIN_CD0_PIN PC0

#define MB_PIN_CD1_PORT PORTC
#define MB_PIN_CD1_DDR DDRC
#define MB_PIN_CD1_PIN PC1

#define MB_PIN_CD2_PORT PORTC
#define MB_PIN_CD2_DDR DDRC
#define MB_PIN_CD2_PIN PC2

#define MB_PIN_CD3_PORT PORTC
#define MB_PIN_CD3_DDR DDRC
#define MB_PIN_CD3_PIN PC3

#define MB_PIN_CD4_PORT PORTD
#define MB_PIN_CD4_DDR DDRD
#define MB_PIN_CD4_PIN PD4

#define MB_PIN_CD5_PORT PORTD
#define MB_PIN_CD5_DDR DDRD
#define MB_PIN_CD5_PIN PD5

#define MB_PIN_CD6_PORT PORTD
#define MB_PIN_CD6_DDR DDRD
#define MB_PIN_CD6_PIN PD6

#define MB_PIN_CD7_PORT PORTD
#define MB_PIN_CD7_DDR DDRD
#define MB_PIN_CD7_PIN PD7

#define MB_PIN_BOARD_RESET_PORT PORTB
#define MB_PIN_BOARD_RESET_DDR DDRB
#define MB_PIN_BOARD_RESET_PIN PB0

#define MB_PIN_INTR_PORT PORTB
#define MB_PIN_INTR_DDR DDRB
#define MB_PIN_INTR_PIN PB1

#define MB_PIN_INTA_PORT PORTB
#define MB_PIN_INTA_DDR DDRB
#define MB_PIN_INTA_INPUT PINB
#define MB_PIN_INTA_PIN PB2

#define MB_PIN_VERA_INT_PORT PORTB
#define MB_PIN_VERA_INT_DDR DDRB
#define MB_PIN_VERA_INT_INPUT PINB
#define MB_PIN_VERA_INT_PIN PB3

#define MB_PIN_IO03_PORT PORTB
#define MB_PIN_IO03_DDR DDRB
#define MB_PIN_IO03_INPUT PINB
#define MB_PIN_IO03_PIN PB4

#define MB_PIN_KB_DATA_PORT PORTB
#define MB_PIN_KB_DATA_DDR DDRB
#define MB_PIN_KB_DATA_INPUT PINB
#define MB_PIN_KB_DATA_PIN PB5

#define MB_PIN_ON_BUTTON_PORT PORTC
#define MB_PIN_ON_BUTTON_DDR DDRC
#define MB_PIN_ON_BUTTON_INPUT PINC
#define MB_PIN_ON_BUTTON_PIN PC4

#define MB_PIN_RESET_BUTTON_PORT PORTC
#define MB_PIN_RESET_BUTTON_DDR DDRC
#define MB_PIN_RESET_BUTTON_INPUT PINC
#define MB_PIN_RESET_BUTTON_PIN PC5

#define MB_PIN_CTRL_RXD_PORT PORTD
#define MB_PIN_CTRL_RXD_DDR DDRD
#define MB_PIN_CTRL_RXD_INPUT PIND
#define MB_PIN_CTRL_RXD_PIN PD0

#define MB_PIN_CTRL_TXD_PORT PORTD
#define MB_PIN_CTRL_TXD_DDR DDRD
#define MB_PIN_CTRL_TXD_PIN PD1

#define MB_PIN_KB_CLK_PORT PORTD
#define MB_PIN_KB_CLK_DDR DDRD
#define MB_PIN_KB_CLK_INPUT PIND
#define MB_PIN_KB_CLK_PIN PD2

#define MB_PIN_SERIAL_INT_PORT PORTD
#define MB_PIN_SERIAL_INT_DDR DDRD
#define MB_PIN_SERIAL_INT_INPUT PIND
#define MB_PIN_SERIAL_INT_PIN PD3

static inline void mb_pin_output(volatile uint8_t *ddr, uint8_t bit)
{
    *ddr |= (uint8_t)_BV(bit);
}

static inline void mb_pin_input(volatile uint8_t *ddr, uint8_t bit)
{
    *ddr &= (uint8_t)~_BV(bit);
}

static inline void mb_pin_high(volatile uint8_t *port, uint8_t bit)
{
    *port |= (uint8_t)_BV(bit);
}

static inline void mb_pin_low(volatile uint8_t *port, uint8_t bit)
{
    *port &= (uint8_t)~_BV(bit);
}

static inline bool mb_pin_read(volatile uint8_t *pin_reg, uint8_t bit)
{
    return ((*pin_reg) & (uint8_t)_BV(bit)) != 0;
}

#endif
