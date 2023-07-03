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
#ifndef _UARTLITE_H_
#define _UARTLITE_H_

#include <stdio.h>

#define UARTLITE_RX_FIFO_OFF		0x00
#define UARTLITE_TX_FIFO_OFF		0x04
#define UARTLITE_STAT_REG_OFF		0x08
#define UARTLITE_CTRL_REG_OFF		0x0c

#define UARTLITE_STAT_RXVALID		(1 << 0)
#define UARTLITE_STAT_RXFULL		(1 << 1)
#define UARTLITE_STAT_TXEMPTY		(1 << 2)
#define UARTLITE_STAT_TXFULL		(1 << 3)
#define UARTLITE_STAT_INTREN		(1 << 4)
#define UARTLITE_STAT_OVERRUN		(1 << 5)
// Frame error
#define UARTLITE_STAT_FRMERR		(1 << 6)
// Parity error
#define UARTLITE_STAT_PARERR		(1 << 7)

#define UARTLITE_CTRL_RSTTXFIFO		(1 << 0)
#define UARTLITE_CTRL_RSTRXFIFO		(1 << 1)
#define UARTLITE_CTRL_ENINTR		(1 << 4)

// Change this to whatever is correct for your project.
#define UARTLITE0_BASE		0xa0010000

#endif
