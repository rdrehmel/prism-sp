/*
 * Copyright (c) 2021-2023 Robert Drehmel
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

/*
 * See [...]/Vitis/2021.1/data/embeddedsw/XilinxProcessorIPLib/drivers/uartps_v3_11
 * for an example standalone driver.
 */
#include "uart.h"
#include "mmio.h"

static void *uart_base = (void *)UART1_BASE;

static inline int
uart_tx_full(void *p)
{
	return (mmio_read(p, UART_SR_OFF) & UART_SR_TXFULL) != 0;
}

static inline int
uart_tx_empty(void *p)
{
	return (mmio_read(p, UART_SR_OFF) & UART_SR_TXEMPTY) != 0;
}

void
uart_send_byte(void *p, uint8_t data)
{
	while (uart_tx_full(p)) {
	}
	mmio_write(p, UART_FIFO_OFF, data);
}

void
serial_putc_stdout(int c)
{
	if (c == '\n')
		uart_send_byte(uart_base, '\r');
	uart_send_byte(uart_base, c);
}

void
uart_puts(const char *s)
{
	for (const char *cp = s; *cp != '\0'; cp++) {
		serial_putc_stdout(*cp);
	}
}

void
uart_init()
{
	// Brute-force copy the configuration of UART0 to UART1.
	for (int i = 0; i < 0x80; i += sizeof(uint32_t)) {
		*(volatile uint32_t *)(UART1_BASE + i) = *(volatile uint32_t *)(UART0_BASE + i);
	}

	uint32_t mode =
		(UART_MR_DATABITS_8 << UART_MR_DATABITS_SHIFT) |
		(UART_MR_PARITY_NONE << UART_MR_PARITY_SHIFT) |
		(UART_MR_STOPBITS_1 << UART_MR_STOPBITS_SHIFT) |
		(UART_MR_WSIZE_1 << UART_MR_WSIZE_SHIFT)
	;
	mmio_write(uart_base, UART_MR_OFF, mode);

	uint32_t ctrl = UART_CR_TXEN;
	mmio_write(uart_base, UART_CR_OFF, ctrl);

	// Disable all interrupts because nobody will handle them.
	mmio_write(uart_base, 0xc, 0x3fff);

	// Set the correct baud rate divider.
	mmio_write(uart_base, UART_BAUDDIV_OFF, 6);

	// Configure the UART1 clock with:
	// DIVISOR0: 0xF
	// DIVISOR1: 0x1
	// CLKACT:   0x1
	mmio_write((void *)CRL_APB_BASE, UART1_REF_CTRL_OFF, 0x01010f00);

	uart_puts("Serial connection initialized to 8N1.\n");
	uart_puts("------------------------------------.\n");
}
