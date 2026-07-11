#include "board.h"

#include <avr/interrupt.h>
#include <avr/io.h>
#include <util/delay.h>

#define TICK_MS 1U
#define POWER_ON_RESET_MS 500U
#define POWER_OFF_HOLD_MS 3000U
#define MANUAL_RESET_MS 200U
#define COUNTER_STEP_MS 1000U

#define CD_LOW_MASK ((uint8_t)(_BV(PC0) | _BV(PC1) | _BV(PC2) | _BV(PC3)))
#define CD_HIGH_MASK ((uint8_t)(_BV(PD4) | _BV(PD5) | _BV(PD6) | _BV(PD7)))

typedef enum {
    BOARD_OFF = 0,
    BOARD_ON,
} board_state_t;

/*
 * Controller #RES is active low. Low holds the board in reset and also
 * clears reset-aware peripherals such as the LED latch.
 */
static void board_reset_assert(void) {
    mb_pin_low(&MB_PIN_BOARD_RESET_PORT, MB_PIN_BOARD_RESET_PIN);
    mb_pin_output(&MB_PIN_BOARD_RESET_DDR, MB_PIN_BOARD_RESET_PIN);
}

/*
 * Controller #RES is active low. High releases the board from reset and allows
 * it to run normally. The board's external pull-down will hold the board in
 * reset until the controller drives the pin high.
 */
static void board_reset_release(void)
{
    mb_pin_high(&MB_PIN_BOARD_RESET_PORT, MB_PIN_BOARD_RESET_PIN);
    mb_pin_output(&MB_PIN_BOARD_RESET_DDR, MB_PIN_BOARD_RESET_PIN);
}

static bool on_button_pressed(void)
{
    return mb_pin_read(&MB_PIN_ON_BUTTON_INPUT, MB_PIN_ON_BUTTON_PIN);
}

static bool reset_button_pressed(void)
{
    return mb_pin_read(&MB_PIN_RESET_BUTTON_INPUT, MB_PIN_RESET_BUTTON_PIN);
}

static void controller_data_bus_write(uint8_t value)
{
    PORTC = (uint8_t)((PORTC & (uint8_t)~CD_LOW_MASK) | (value & 0x0F));
    PORTD = (uint8_t)((PORTD & (uint8_t)~CD_HIGH_MASK) | (value & 0xF0));
}

static void controller_data_bus_output(void)
{
    DDRC |= CD_LOW_MASK;
    DDRD |= CD_HIGH_MASK;
}

static void gpio_init(void)
{
    cli();

    board_reset_assert();

    mb_pin_input(&MB_PIN_ON_BUTTON_DDR, MB_PIN_ON_BUTTON_PIN);
    mb_pin_input(&MB_PIN_RESET_BUTTON_DDR, MB_PIN_RESET_BUTTON_PIN);

    mb_pin_low(&MB_PIN_INTR_PORT, MB_PIN_INTR_PIN);
    mb_pin_output(&MB_PIN_INTR_DDR, MB_PIN_INTR_PIN);

    controller_data_bus_write(0x00);
    controller_data_bus_output();
}

int main(void)
{
    board_state_t board_state = BOARD_OFF;
    bool on_was_pressed = false;
    bool reset_was_pressed = false;
    uint16_t on_hold_ms = 0;
    uint16_t reset_timer_ms = 0;

    gpio_init();

    for (;;) {
        const bool on_pressed = on_button_pressed();
        const bool reset_pressed = reset_button_pressed();

        /*
         * ON button:
         * - rising edge while off starts the board with a 500 ms reset hold;
         * - holding while fully on for 3 seconds returns to reset/off.
         */
        if (on_pressed) {
            if (!on_was_pressed) {
                on_hold_ms = 0;

                if (board_state == BOARD_OFF) {
                    board_state = BOARD_ON;
                    reset_timer_ms = POWER_ON_RESET_MS;
                }
            } else if (on_hold_ms < POWER_OFF_HOLD_MS) {
                on_hold_ms += TICK_MS;
            }

            if ((board_state == BOARD_ON) &&
                (reset_timer_ms == 0) &&
                (on_hold_ms >= POWER_OFF_HOLD_MS)) {
                board_state = BOARD_OFF;
                reset_timer_ms = 0;
            }
        } else {
            on_hold_ms = 0;
        }

        if ((board_state == BOARD_ON) && reset_pressed && !reset_was_pressed) {
            reset_timer_ms = MANUAL_RESET_MS;
        }

        if ((board_state == BOARD_OFF) || (reset_timer_ms > 0)) {
            board_reset_assert();   // turn board off (reset active)
            controller_data_bus_write(0x00);
        } else {
            board_reset_release();  // turn board on (reset inactive)
            controller_data_bus_write(0xAA);
        }

        if (reset_timer_ms > 0) {
            reset_timer_ms -= TICK_MS;
        }

        on_was_pressed = on_pressed;
        reset_was_pressed = reset_pressed;

        _delay_ms(TICK_MS);
    }
}
