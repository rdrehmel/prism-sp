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
#ifndef _UART_H_
#define _UART_H_

#include <stdio.h>

#define UART_CR_OFF			0x00
#define UART_MR_OFF			0x04
#define UART_SR_OFF			0x2c
#define UART_FIFO_OFF		0x30
#define UART_BAUDDIV_OFF	0x34

// Control register bits
#define UART_CR_RXRES				((uint32_t)1 << 0)
#define UART_CR_TXRES				((uint32_t)1 << 1)
#define UART_CR_RXEN				((uint32_t)1 << 2)
#define UART_CR_RXDIS				((uint32_t)1 << 3)
#define UART_CR_TXEN				((uint32_t)1 << 4)
#define UART_CR_TXDIS				((uint32_t)1 << 5)

// Mode register bits
#define UART_MR_DATABITS_8			0x0
#define UART_MR_DATABITS_7			0x2
#define UART_MR_DATABITS_6			0x3
#define UART_MR_DATABITS_SHIFT		1
#define UART_MR_DATABITS_MASK		0x3
#define UART_MR_DATABITS_SMASK		(UART_MR_DATABITS_MASK << UART_MR_DATABITS_SHIFT)

#define UART_MR_PARITY_NONE			4
#define UART_MR_PARITY_SHIFT		3
#define UART_MR_PARITY_MASK			0x7
#define UART_MR_PARITY_SMASK		(UART_MR_PARITY_MASK << UART_MR_PARITY_SHIFT)

#define UART_MR_STOPBITS_1			0x0
#define UART_MR_STOPBITS_1_5		0x1
#define UART_MR_STOPBITS_2			0x2
#define UART_MR_STOPBITS_SHIFT		6
#define UART_MR_STOPBITS_MASK		0x3
#define UART_MR_STOPBITS_SMASK		(UART_MR_STOPBITS_MASK << UART_MR_STOPBITS_SHIFT)

#define UART_MR_WSIZE_BYTE_SEL		0x0
#define UART_MR_WSIZE_1				0x1
#define UART_MR_WSIZE_2				0x2
#define UART_MR_WSIZE_4				0x3
#define UART_MR_WSIZE_SHIFT			12
#define UART_MR_WSIZE_MASK			0x3
#define UART_MR_WSIZE_SMASK			(UART_MR_WSIZE_SHIFT << UART_MR_WSIZE_MASK)

// Status register bits
#define UART_SR_TXFULL		((uint32_t)1 << 4)
#define UART_SR_TXEMPTY		((uint32_t)1 << 3)

#define UART0_BASE				0xff000000
#define UART1_BASE				0xff010000

#define CRL_APB_BASE			0xff5e0000
#define UART0_REF_CTRL_OFF		0x74
#define UART1_REF_CTRL_OFF		0x78

void serial_putc_stdout(int);

#endif
