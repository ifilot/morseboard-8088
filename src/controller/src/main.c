#include "board.h"

#include <avr/interrupt.h>
#include <avr/io.h>
#include <util/delay.h>

#define TICK_MS 1U
#define POWER_ON_DELAY_MS 500U
#define POWER_OFF_HOLD_MS 3000U
#define MANUAL_RESET_MS 200U

typedef enum {
    BOARD_OFF = 0,
    BOARD_ON,
} board_power_state_t;

static void board_reset_assert(void)
{
    /*
     * RES is held low by default. Driving PB0 low keeps the 8088 board in
     * reset, which is also our "off" state until real power control exists.
     */
    mb_pin_low(&MB_PIN_BOARD_RESET_PORT, MB_PIN_BOARD_RESET_PIN);
    mb_pin_output(&MB_PIN_BOARD_RESET_DDR, MB_PIN_BOARD_RESET_PIN);
}

static void board_reset_release(void)
{
    /* Releasing reset lets the 8088 board start running. */
    mb_pin_high(&MB_PIN_BOARD_RESET_PORT, MB_PIN_BOARD_RESET_PIN);
}

static bool on_button_pressed(void)
{
    return mb_pin_read(&MB_PIN_ON_BUTTON_INPUT, MB_PIN_ON_BUTTON_PIN);
}

static bool reset_button_pressed(void)
{
    return mb_pin_read(&MB_PIN_RESET_BUTTON_INPUT, MB_PIN_RESET_BUTTON_PIN);
}

static void data_bus_init(void)
{
    /*
     * CD0..CD7 will eventually carry keyboard-controller data onto the system
     * bus. For now the controller never drives them; the external buffer and
     * future bus-enable logic can be added around this quiet default.
     */
    DDRC &= (uint8_t)~(_BV(PC0) | _BV(PC1) | _BV(PC2) | _BV(PC3));
    PORTC &= (uint8_t)~(_BV(PC0) | _BV(PC1) | _BV(PC2) | _BV(PC3));

    DDRD &= (uint8_t)~(_BV(PD4) | _BV(PD5) | _BV(PD6) | _BV(PD7));
    PORTD &= (uint8_t)~(_BV(PD4) | _BV(PD5) | _BV(PD6) | _BV(PD7));
}

static void gpio_init(void)
{
    /*
     * Interrupt handling is intentionally disabled in this first firmware.
     * The controller will eventually arbitrate interrupt sources, but for now
     * every signal is polled or left passive.
     */
    cli();

    board_reset_assert();
    data_bus_init();

    mb_pin_input(&MB_PIN_RESET_BUTTON_DDR, MB_PIN_RESET_BUTTON_PIN);
    mb_pin_input(&MB_PIN_ON_BUTTON_DDR, MB_PIN_ON_BUTTON_PIN);
    mb_pin_input(&MB_PIN_INTA_DDR, MB_PIN_INTA_PIN);
    mb_pin_input(&MB_PIN_IO03_DDR, MB_PIN_IO03_PIN);
    mb_pin_input(&MB_PIN_VERA_INT_DDR, MB_PIN_VERA_INT_PIN);
    mb_pin_input(&MB_PIN_SERIAL_INT_DDR, MB_PIN_SERIAL_INT_PIN);
    mb_pin_input(&MB_PIN_KB_CLK_DDR, MB_PIN_KB_CLK_PIN);
    mb_pin_input(&MB_PIN_KB_DATA_DDR, MB_PIN_KB_DATA_PIN);
    mb_pin_input(&MB_PIN_CTRL_RXD_DDR, MB_PIN_CTRL_RXD_PIN);

    /*
     * Keep the CPU interrupt-request line inactive. This assumes the board
     * treats low on INTR as "no interrupt"; adjust this when interrupt
     * polarity is finalized.
     */
    mb_pin_low(&MB_PIN_INTR_PORT, MB_PIN_INTR_PIN);
    mb_pin_output(&MB_PIN_INTR_DDR, MB_PIN_INTR_PIN);
}

int main(void)
{
    board_power_state_t board_state = BOARD_OFF;
    bool on_button_was_pressed = false;
    bool reset_button_was_pressed = false;
    uint16_t on_button_hold_ms = 0;
    uint16_t reset_timer_ms = 0;

    gpio_init();

    for (;;) {
        const bool on_pressed = on_button_pressed();
        const bool reset_pressed = reset_button_pressed();

        /*
         * ON button behavior:
         * - a new press while off starts a 500 ms reset hold, then boots;
         * - holding it for 3 seconds while on returns the board to reset.
         */
        if (on_pressed) {
            if (!on_button_was_pressed) {
                on_button_hold_ms = 0;

                if (board_state == BOARD_OFF) {
                    board_state = BOARD_ON;
                    reset_timer_ms = POWER_ON_DELAY_MS;
                }
            } else if (on_button_hold_ms < POWER_OFF_HOLD_MS) {
                on_button_hold_ms += TICK_MS;
            }

            if ((board_state == BOARD_ON) && (on_button_hold_ms >= POWER_OFF_HOLD_MS)) {
                board_state = BOARD_OFF;
                reset_timer_ms = 0;
            }
        } else {
            on_button_hold_ms = 0;
        }

        /*
         * RESET button behavior:
         * trigger one 200 ms reset pulse on the rising edge of RESET_BTN.
         */
        if ((board_state == BOARD_ON) && reset_pressed && !reset_button_was_pressed) {
            reset_timer_ms = MANUAL_RESET_MS;
        }

        /*
         * Reset output policy:
         * - off means reset asserted forever;
         * - on with an active timer means a temporary reset pulse;
         * - on with no timer means reset released.
         */
        if ((board_state == BOARD_OFF) || (reset_timer_ms > 0)) {
            board_reset_assert();
        } else {
            board_reset_release();
        }

        if (reset_timer_ms > 0) {
            reset_timer_ms -= TICK_MS;
        }

        on_button_was_pressed = on_pressed;
        reset_button_was_pressed = reset_pressed;

        _delay_ms(TICK_MS);
    }
}
