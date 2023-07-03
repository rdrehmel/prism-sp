/*
 * Copyright (c) 2023 Robert Drehmel
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <stdint.h>

#include "uartlite.h"
#include "mmio.h"

static void *uartlite_base = (void *)UARTLITE0_BASE;

static inline int
uartlite_tx_full(void *p)
{
	return (mmio_read(p, UARTLITE_STAT_REG_OFF) & UARTLITE_STAT_TXFULL) != 0;
}

static inline int
uartlite_tx_empty(void *p)
{
	return (mmio_read(p, UARTLITE_STAT_REG_OFF) & UARTLITE_STAT_TXEMPTY) != 0;
}

void
uartlite_send_byte(void *p, uint8_t data)
{
	while (uartlite_tx_full(p)) {
	}
	mmio_write(p, UARTLITE_TX_FIFO_OFF, data);
}

void
serial_putc_stdout(int c)
{
	if (c == '\n')
		uartlite_send_byte(uartlite_base, '\r');
	uartlite_send_byte(uartlite_base, c);
}

void
uartlite_puts(const char *s)
{
	for (const char *cp = s; *cp != '\0'; cp++) {
		serial_putc_stdout(*cp);
	}
}

void
uartlite_init()
{
	uint32_t ctrl = UARTLITE_CTRL_RSTTXFIFO | UARTLITE_CTRL_RSTRXFIFO;

	// There is not much to set here.
	// Reset both FIFOs and disable interrupts.
	mmio_write(uartlite_base, UARTLITE_CTRL_REG_OFF, ctrl);

	uartlite_puts("Uartlite serial connection initialized to 8N1.\n");
	uartlite_puts("---------------------------------------------.\n");
}
