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
#include <stdbool.h>
#include <stdio.h>

#include "mmio.h"
#include "csr.h"
#include "sp.h"
#include "sp-desc.h"
#include "sp-desc-rx.h"
#include "sp-desc-tx.h"
#include "gem.h"

//#define DEBUG

extern void uartlite_init();

int
main()
{
	uint32_t x;

	uartlite_init();

	printf("----\n");
	printf("Stream Processor/GEM DUO (OpenHW) TX desc firmware version 0.1d\n");
	printf("----\n");
	printf("Waiting for start signal.\n");

	mmio_write((void *)0xfd6e0000, 0x4000, 0x1);

	uint32_t enable_bits = 1 << SP_CONTROL_ENABLE_TX_BITN;
	do {
		x = sp_load_reg(SP_REGN_CONTROL);
	} while ((x & enable_bits) != enable_bits);
	printf("Received start signal.\n");

	prism_set_caching();
	prism_print_caching();

	printf("----\n");
	printf("Fetching private DMA configuration.\n");
	load_tx_config();
	load_desc_tx_config();

	sp_acp_set_local_wstrb_0(0x0000ffff);
	sp_acp_set_local_wstrb_1(0x0000ffff);
	sp_acp_set_local_wstrb_2(0x0000ffff);
	sp_acp_set_local_wstrb_3(0x0000ffff);

	for (;;) {
		uint32_t x = sp_load_reg(SP_REGN_CONTROL);
		if (x & (1 << SP_CONTROL_START_TX_BITN)) {
			sp_store_reg(SP_REGN_CONTROL, x ^ (1 << SP_CONTROL_START_TX_BITN));
			while (tx(0)) { }
			while (tx(1)) { }
		}
	}
	printf("Done.\n");

	return 0;
}
