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
#include "sp-desc-tx.h"
#include "gem.h"
#include "gem-dma.h"

#define DEBUG

extern struct sp_config tx_config;

struct sp_desc_gem_tx_queue tx_queues[NQUEUES];

void prism_hexdump(const void *na, int nbytes);

int
tx_queue_no(struct sp_desc_gem_tx_queue *tx_queue)
{
	return tx_queue - tx_queues;
}

void
load_desc_tx_config(void)
{
	tx_queues[0].q.dma_desc_base =
		(gem_tx_dma_desc_word_type *)sp_load_reg(SP_REGN_TX_DMA_DESC_BASE_0);
	tx_queues[0].q.cur_dma_desc_addr = tx_queues[0].q.dma_desc_base;

	tx_queues[1].q.dma_desc_base =
		(gem_tx_dma_desc_word_type *)sp_load_reg(SP_REGN_TX_DMA_DESC_BASE_1);
	tx_queues[1].q.cur_dma_desc_addr = tx_queues[1].q.dma_desc_base;

	for (int i = 0; i < NQUEUES; i++) {
		tx_queues[i].q.prefetch_primed = 0;
		tx_queues[i].q.prefetch_addr = (void *)(uintptr_t)(0x30000 + i * 64);
		tx_queues[i].saved_cur_dma_desc_addr = NULL;
		tx_queues[i].saved_dma_desc_1 = 0;
		sp_gem_queue_init(&tx_queues[i].q.base, i);
	}

	printf("Descriptor base of TX queue 0 is at %p\n", tx_queues[0].q.dma_desc_base);
	printf("Descriptor base of TX queue 1 is at %p\n", tx_queues[1].q.dma_desc_base);
}

struct gem_tx_dma_desc {
	gem_tx_dma_desc_word_type dma_desc_0;
	gem_tx_dma_desc_word_type dma_desc_1;
};

#define PRISM_SP_DESC_TX_OPT
#ifdef PRISM_SP_DESC_TX_OPT
static inline int
sp_desc_tx_get_desc(
	struct sp_desc_gem_tx_queue *tx_queue,
	struct gem_tx_dma_desc *desc
)
{

	for (int i = 0; i < 2; i++) {
		register gem_tx_dma_desc_word_type *prefetch_addr = tx_queue->q.prefetch_addr;
		if (!tx_queue->q.prefetch_primed) {
			while (sp_acp_busy()) {
			}

#ifdef DEBUG
			printf("[tx%d,cur=%p] get_desc(): read(0x%x, 0x%x)\n",
				tx_queue_no(tx_queue),
				tx_queue->q.cur_dma_desc_addr,
				(uint32_t)prefetch_addr,
				(uint32_t)tx_queue->q.cur_dma_desc_addr & ~(uint32_t)(64 - 1)
			);
#endif
			sp_acp_read_start_64((uint32_t)prefetch_addr, (uint32_t)tx_queue->q.cur_dma_desc_addr & ~(uint32_t)(64 - 1));

			while (sp_acp_busy()) {
			}

			tx_queue->q.prefetch_primed = 1;
		}
		prefetch_addr = (gem_tx_dma_desc_word_type *)((uint32_t)prefetch_addr | ((uint32_t)tx_queue->q.cur_dma_desc_addr & (64 - 1)));
		desc->dma_desc_0 = prefetch_addr[0];
		desc->dma_desc_1 = prefetch_addr[1];
#ifdef DEBUG
		printf("[tx%d,cur=%p] get_desc(): prefetch_addr=0x%08x [0]=0x%08x [1]=0x%08x\n",
			tx_queue_no(tx_queue),
			tx_queue->q.cur_dma_desc_addr,
			(uint32_t)prefetch_addr,
			desc->dma_desc_0,
			desc->dma_desc_1
		);
#endif

		if (!(desc->dma_desc_1 & (1 << GEM_TX_DD1_VALID_BITN))) {
			return 0;
		}
#ifdef DEBUG
		printf("[tx%d,cur=%p] get_desc(): no desc., repriming.\n",
			tx_queue_no(tx_queue),
			tx_queue->q.cur_dma_desc_addr
		);
#endif
		tx_queue->q.prefetch_primed = 0;
	}
#ifdef DEBUG
	printf("[tx%d,cur=%p] get_desc(): still no desc, giving up.\n",
		tx_queue_no(tx_queue),
		tx_queue->q.cur_dma_desc_addr
	);
#endif

	return 1;
}

static inline void
sp_desc_tx_save_desc(
	struct sp_desc_gem_tx_queue *tx_queue,
	struct gem_tx_dma_desc *desc
)
{
	tx_queue->saved_dma_desc_1 = desc->dma_desc_1;
	tx_queue->saved_cur_dma_desc_addr = tx_queue->q.cur_dma_desc_addr;
}

static inline void
sp_desc_tx_validate_saved_desc(
	struct sp_desc_gem_tx_queue *tx_queue
)
{
	register uint32_t saved_cur_dma_desc_addr = (uint32_t)tx_queue->saved_cur_dma_desc_addr;
	register gem_tx_dma_desc_word_type *scratch_addr = tx_queue->q.base.scratch_addr;
	gem_tx_dma_desc_word_type dma_desc_1 = tx_queue->saved_dma_desc_1;
	dma_desc_1 |= (uint32_t)1 << GEM_TX_DD1_VALID_BITN;

	while (sp_acp_busy()) {
	}
	if (saved_cur_dma_desc_addr & (16 / 2)) {
		sp_acp_set_remote_wstrb_0(0x0000f000);
		scratch_addr[3] = dma_desc_1;
	}
	else {
		sp_acp_set_remote_wstrb_0(0x000000f0);
		scratch_addr[1] = dma_desc_1;
	}
	// Align to 16 bits.
	saved_cur_dma_desc_addr &= ~(uint32_t)(16-1);
#ifdef DEBUG
	printf("[tx%d] write(0x%08x, 0x%08x)\n",
		tx_queue_no(tx_queue),
		(uint32_t)scratch_addr,
		saved_cur_dma_desc_addr);
#endif
	sp_acp_write_start_16((uint32_t)scratch_addr, saved_cur_dma_desc_addr);
	while (sp_acp_busy()) { }
}

static inline void
sp_desc_tx_next_desc(
	struct sp_desc_gem_tx_queue *tx_queue,
	struct gem_tx_dma_desc *desc
)
{
	if (desc->dma_desc_1 & (1 << GEM_TX_DD1_WRAP_BITN)) {
		tx_queue->q.cur_dma_desc_addr = tx_queue->q.dma_desc_base;
		tx_queue->q.prefetch_primed = 0;
	}
	else {
		tx_queue->q.cur_dma_desc_addr += 2;
		if (((uint32_t)tx_queue->q.cur_dma_desc_addr & (64-1)) == 0x00) {
			tx_queue->q.prefetch_primed = 0;
		}
	}
}
#else
static inline int
sp_desc_tx_get_desc(
	struct sp_desc_gem_tx_queue *tx_queue,
	struct gem_tx_dma_desc *desc
)
{
	gem_tx_dma_desc_word_type *dma_descp = tx_queue->q.cur_dma_desc_addr;
	gem_tx_dma_desc_word_type dma_desc_1 = *(dma_descp + 1);
	if (dma_desc_1 & (1 << GEM_TX_DD1_VALID_BITN)) {
		return 1;
	}
	gem_tx_dma_desc_word_type dma_desc_0 = *(dma_descp + 0);

	desc->dma_desc_0 = dma_desc_0;
	desc->dma_desc_1 = dma_desc_1;
	return 0;
}

static inline void
sp_desc_tx_save_desc(
	struct sp_desc_gem_tx_queue *tx_queue,
	struct gem_tx_dma_desc *desc
)
{
	tx_queue->saved_cur_dma_desc_addr = tx_queue->q.cur_dma_desc_addr;
	tx_queue->saved_dma_desc_1 = desc->dma_desc_1;
}

static inline void
sp_desc_tx_validate_saved_desc(
	struct sp_desc_gem_tx_queue *tx_queue
)
{
	// Mark the first descriptor of this packet as usable by the driver
	// Note that only the first descriptor is set to valid.
	tx_queue->saved_dma_desc_1 |= (uint32_t)1 << GEM_TX_DD1_VALID_BITN;
	tx_queue->saved_cur_dma_desc_addr[1] = tx_queue->saved_dma_desc_1;
}

static inline void
sp_desc_tx_next_desc(
	struct sp_desc_gem_tx_queue *tx_queue,
	struct gem_tx_dma_desc *desc
)
{
	// On to the next descriptor in any case.
	if (desc->dma_desc_1 & (1 << GEM_TX_DD1_WRAP_BITN)) {
		tx_queue->q.cur_dma_desc_addr = tx_queue->q.dma_desc_base;
	}
	else {
		tx_queue->q.cur_dma_desc_addr += 2;
	}
}
#endif

/*
 * Called when triggered by MMIO.
 */
int
tx(int q)
{
	struct sp_desc_gem_tx_queue *tx_queue = &tx_queues[q];
	gem_tx_dma_desc_word_type *packet_dma_descp;
	gem_tx_dma_desc_word_type packet_dma_desc_1;
	int packet_length = 0;
	int ntxdescs = 0;
	bool no_crc;

	for (;;) {
		struct gem_tx_dma_desc desc;

		// Get the next descriptor from DRAM
		if (sp_desc_tx_get_desc(tx_queue, &desc))
			return 0;

		ntxdescs++;

		// If this is the first descriptor of this packet.
		if (packet_length == 0) {
			sp_desc_tx_save_desc(tx_queue, &desc);
			no_crc = (desc.dma_desc_1 & (1 << GEM_TX_DD1_NOCRC_BITN)) != 0;
		}

		// Get the DRAM address and length of the payload buffer
		dma_addr_t data_addr = gem_tx_dma_desc0_get_addr(desc.dma_desc_0);
		int data_length = gem_tx_dma_desc1_get_length(desc.dma_desc_1);

#ifdef DEBUG
		printf("%sTX: 0:0x%08x 1:0x%08x addr=0x%08x len=%d\n",
			packet_length == 0 ? " " : "+",
			desc.dma_desc_0, desc.dma_desc_1, data_addr, data_length);
#endif

		bool eof = (desc.dma_desc_1 & (1 << GEM_TX_DD1_EOF_BITN)) != 0;
		uint32_t count;
		for (;;) {
			count = sp_tx_data_count();
			if (tx_config.data_fifo_size - count >= data_length)
				break;
		}

		sp_tx_data_dma_start(data_addr, (uint32_t)!eof << 31 | data_length);
		int niters;
		for (niters = 0;; niters++) {
			uint32_t status = sp_tx_data_dma_status();
			if (status == 0) {
				break;
			}
		}

		packet_length += data_length;

		sp_desc_tx_next_desc(tx_queue, &desc);

		if (eof) {
			sp_desc_tx_validate_saved_desc(tx_queue);

			// Store the descriptor in the BRAM
			sp_tx_meta_push_uint32((uint32_t)no_crc << TX_META_DESC_NO_CRC_BITN | packet_length);
			break;
		}
	}
	if (ntxdescs > 0) {
		// Send TX done interrupt
		gem_tx_done(q);
	}

	// Retval:
	// 0  : No more descriptors
	// >=1: Possibly more descriptors
	return ntxdescs;
}
