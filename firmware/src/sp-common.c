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
#include <stdio.h>

#include "sp.h"

void
sp_gem_queue_init(struct sp_gem_queue *queue, int i)
{
	queue->scratch_addr = (void *)(uintptr_t)(0x30000 + 2 * 64 + i * 16);
}

void
prism_hexdump(const void *na, int nbytes)
{
	uint8_t *p = (uint8_t *)na;
	int i;

	for (i = 0; i < nbytes; i += 16) {
		printf(
			"%p | "
			"0x%02x 0x%02x 0x%02x 0x%02x   "
			"0x%02x 0x%02x 0x%02x 0x%02x   "
			"0x%02x 0x%02x 0x%02x 0x%02x   "
			"0x%02x 0x%02x 0x%02x 0x%02x |\n",
			p,
			p[0], p[1], p[2], p[3],
			p[4], p[5], p[6], p[7],
			p[8], p[9], p[10], p[11],
			p[12], p[13], p[14], p[15]
		);
		p += 16;
	}
}

void
printf_b(uint32_t x, int n)
{
	if (n > sizeof(x) * 8)
		n = sizeof(x) * 8;

	for (int i = 0; i < n; i++) {
		uint8_t y = (x & ((uint32_t)1 << (n - i - 1))) != 0;
		printf("%d", y);
	}
}

void
prism_set_caching(void)
{
	sp_store_reg(SP_REGN_IO_AXI_AXCACHE, 0x0);
	sp_store_reg(SP_REGN_DMA_AXI_AXCACHE, 0x0);
}

void
prism_print_caching(void)
{
	uint32_t x;

	printf("----\n");
	printf("Fetching private caching configuration.\n");
	x = sp_load_reg(SP_REGN_IO_AXI_AXCACHE);
	printf("I/O Caching: 0x%x/", x);
	printf_b(x, 4);
	printf("\n");
	x = sp_load_reg(SP_REGN_DMA_AXI_AXCACHE);
	printf("DMA Caching: 0x%x/", x);
	printf_b(x, 4);
	printf("\n");
}
