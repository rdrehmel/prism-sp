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
#include <stdio.h>

#include "sp.h"
#include "sp-desc.h"
#include "sp-desc-rx.h"
#include "gem.h"
#include "gem-dma.h"

#define DEBUG

extern struct sp_config rx_config;

struct sp_desc_gem_rx_queue rx_queues[NQUEUES];

void prism_hexdump(const void *na, int nbytes);

int
rx_queue_no(struct sp_desc_gem_rx_queue *rx_queue)
{
	return rx_queue - rx_queues;
}

void
load_desc_rx_config(void)
{
	rx_queues[0].q.dma_desc_base =
		(gem_rx_dma_desc_word_type *)sp_load_reg(SP_REGN_RX_DMA_DESC_BASE_0);
	rx_queues[0].q.cur_dma_desc_addr = rx_queues[0].q.dma_desc_base;

	rx_queues[1].q.dma_desc_base =
		(gem_rx_dma_desc_word_type *)sp_load_reg(SP_REGN_RX_DMA_DESC_BASE_1);
	rx_queues[1].q.cur_dma_desc_addr = rx_queues[1].q.dma_desc_base;

	for (int i = 0; i < NQUEUES; i++) {
		rx_queues[i].q.prefetch_primed = 0;
		rx_queues[i].q.prefetch_addr = (void *)(uintptr_t)(0x30000 + i * 64);
		sp_gem_queue_init(&rx_queues[i].q.base, i);
	}

	printf("Descriptor base of RX queue 0 is at %p\n", rx_queues[0].q.dma_desc_base);
	printf("Descriptor base of RX queue 1 is at %p\n", rx_queues[1].q.dma_desc_base);
}

struct gem_rx_dma_desc {
	gem_rx_dma_desc_word_type dma_desc_0;
	gem_rx_dma_desc_word_type dma_desc_1;
};

#define PRISM_SP_DESC_RX_OPT
#ifdef PRISM_SP_DESC_RX_OPT
static inline int
sp_desc_rx_get_desc(
	struct sp_desc_gem_rx_queue *rx_queue,
	struct gem_rx_dma_desc *desc
)
{
	// Attention: Don't call twice without a call to sp_desc_rx_next_desc()
	// in between. You would trigger the prefetching again.

	for (int i = 0; i < 2; i++) {
		register gem_rx_dma_desc_word_type *prefetch_addr = rx_queue->q.prefetch_addr;
		if (!rx_queue->q.prefetch_primed) {
			while (sp_acp_busy()) {
			}

#ifdef DEBUG
			printf("[rx%d,cur=%p] read(0x%08x, 0x%08x)\n",
				rx_queue_no(rx_queue),
				rx_queue->q.cur_dma_desc_addr,
				(uint32_t)prefetch_addr,
				(uint32_t)rx_queue->q.cur_dma_desc_addr & ~(uint32_t)(64 - 1));
#endif

			sp_acp_read_start_64((uint32_t)prefetch_addr, (uint32_t)rx_queue->q.cur_dma_desc_addr & ~(uint32_t)(64 - 1));

			while (sp_acp_busy()) {
			}

			rx_queue->q.prefetch_primed = 1;
		}
		prefetch_addr = (gem_rx_dma_desc_word_type *)((uint32_t)prefetch_addr | ((uint32_t)rx_queue->q.cur_dma_desc_addr & (64 - 1)));
		desc->dma_desc_0 = prefetch_addr[0];
		desc->dma_desc_1 = prefetch_addr[1];
#ifdef DEBUG
		printf("[rx%d,cur=%p] prefetch_addr=0x%08x [0]=0x%08x [1]=0x%08x\n",
			rx_queue_no(rx_queue),
			rx_queue->q.cur_dma_desc_addr,
			(uint32_t)prefetch_addr,
			desc->dma_desc_0,
			desc->dma_desc_1);
#endif

		if (!(desc->dma_desc_0 & (1 << GEM_RX_DD0_VALID_BITN))) {
			return 0;
		}
		rx_queue->q.prefetch_primed = 0;
	}
	return 1;
}

static inline void
sp_desc_rx_set_desc_(
	struct sp_desc_gem_rx_queue *rx_queue,
	gem_rx_dma_desc_word_type dma_desc_0,
	gem_rx_dma_desc_word_type dma_desc_1
)
{
	register gem_rx_dma_desc_word_type *prefetch_addr = rx_queue->q.prefetch_addr;
	prefetch_addr = (gem_rx_dma_desc_word_type *)((uint32_t)prefetch_addr | ((uint32_t)rx_queue->q.cur_dma_desc_addr & (64 - 1)));
	prefetch_addr[0] = dma_desc_0;
	prefetch_addr[1] = dma_desc_1;

	register uint32_t cur_dma_desc_addr = (uint32_t)rx_queue->q.cur_dma_desc_addr;

	while (sp_acp_busy()) {
	}
	// Set the write strobes.
	// Words 0 and 1 are in the LSBs.
	// Words 2 and 3 are in the MSBs.
	if (cur_dma_desc_addr & (16 / 2)) {
		sp_acp_set_remote_wstrb_0(0x0000ff00);
	}
	else {
		sp_acp_set_remote_wstrb_0(0x000000ff);
	}

	// We need to transfer the whole 128-bit word, so align the address to
	// an 16-byte boundary.
	register uint32_t mask = ~(uint32_t)(16 - 1);
	prefetch_addr = (void *)((uintptr_t)prefetch_addr & mask);
	uint32_t cur_dma_desc_addr_aligned = cur_dma_desc_addr & mask;
#ifdef DEBUG
	printf("[rx%d] write(0x%08x, 0x%08x)\n",
		rx_queue_no(rx_queue),
		(uint32_t)prefetch_addr,
		cur_dma_desc_addr_aligned);
#endif
	sp_acp_write_start_16((uint32_t)prefetch_addr, cur_dma_desc_addr_aligned);
}


static inline void
sp_desc_rx_next_desc(
	struct sp_desc_gem_rx_queue *rx_queue,
	struct gem_rx_dma_desc *desc
)
{
	if (desc->dma_desc_0 & (1 << GEM_RX_DD0_WRAP_BITN)) {
		rx_queue->q.cur_dma_desc_addr = rx_queue->q.dma_desc_base;
		rx_queue->q.prefetch_primed = 0;
	}
	else {
		rx_queue->q.cur_dma_desc_addr += 2;
		if (((uint32_t)rx_queue->q.cur_dma_desc_addr & (64 - 1)) == 0x00) {
			rx_queue->q.prefetch_primed = 0;
		}
	}
}
#else
static inline int
sp_desc_rx_get_desc(
	struct sp_desc_gem_rx_queue *rx_queue,
	struct gem_rx_dma_desc *desc
)
{
	// Get next descriptor from DRAM
	gem_rx_dma_desc_word_type *dma_descp = rx_queue->q.cur_dma_desc_addr;
	gem_rx_dma_desc_word_type dma_desc_0 = *(dma_descp + 0);
	if (dma_desc_0 & (1 << GEM_RX_DD0_VALID_BITN)) {
		//printf("RX: There are no free descriptors!\n");
		return 1;
	}
	// XXX We currently only support 32-bit addresses.
#ifdef GEM_64BIT_DESC
	gem_rx_dma_desc_word_type dma_desc_2 = *(dma_descp + 2);
#endif
	gem_rx_dma_desc_word_type dma_desc_1 = *(dma_descp + 1);

	desc->dma_desc_0 = dma_desc_0;
	desc->dma_desc_1 = dma_desc_1;

	return 0;
}

static inline void
sp_desc_rx_set_desc_(
	struct sp_desc_gem_rx_queue *rx_queue,
	gem_rx_dma_desc_word_type dma_desc_0,
	gem_rx_dma_desc_word_type dma_desc_1
)
{
	gem_rx_dma_desc_word_type *dma_descp = rx_queue->q.cur_dma_desc_addr;

	// Set all the other parameters.
	*(dma_descp + 1) = dma_desc_1;
	*(dma_descp + 0) = dma_desc_0;
}

static inline void
sp_desc_rx_next_desc(
	struct sp_desc_gem_rx_queue *rx_queue,
	struct gem_rx_dma_desc *desc
)
{
	// On to the next descriptor
	if (desc->dma_desc_0 & (1 << GEM_RX_DD0_WRAP_BITN)) {
		rx_queue->q.cur_dma_desc_addr = rx_queue->q.dma_desc_base;
	}
	else {
		rx_queue->q.cur_dma_desc_addr += 2;
	}
}
#endif

static inline void
sp_desc_rx_set_desc(
	struct sp_desc_gem_rx_queue *rx_queue,
	struct gem_rx_dma_desc *desc
)
{
	sp_desc_rx_set_desc_(rx_queue, desc->dma_desc_0, desc->dma_desc_1);
}

/*
 * Called when triggered by the GEM FIFO interface.
 */
int
rx(int q)
{
	struct sp_desc_gem_rx_queue *rx_queue = &rx_queues[q];
	struct gem_rx_dma_desc desc;

	if (sp_desc_rx_get_desc(rx_queue, &desc))
		return 1;

	// Get meta information from BRAM
	gem_rx_meta_desc_type meta_desc = sp_rx_meta_pop_uint32();

	// Do nothing with the data just received
	// ...
	// Could skip, could modify.

	// Get the destination of the buffer in DRAM
	dma_addr_t data_addr = gem_rx_dma_desc0_get_addr(desc.dma_desc_0);
	// Get length from BRAM
	int data_length = gem_rx_meta_desc_get_length(meta_desc);
#ifdef DEBUG
	printf(" RX: 0:0x%08x 1:0x%08x addr=0x%08x len=%d meta=0x%08x\n",
		desc.dma_desc_0, desc.dma_desc_1, data_addr, data_length, meta_desc);
#endif

	sp_rx_data_dma_start(data_addr, data_length);
	int niters;
	for (niters = 0;; niters++) {
		uint32_t status = sp_rx_data_dma_status();
		if (status == 0) {
			break;
		}
	}

	// Update DRAM descriptor to be valid
	desc.dma_desc_0 |= 1 << GEM_RX_DD0_VALID_BITN;
	sp_desc_rx_set_desc_(rx_queue, desc.dma_desc_0, meta_desc);

	sp_desc_rx_next_desc(rx_queue, &desc);

	// Send the RX done interrupt
	gem_rx_done(q);
}
