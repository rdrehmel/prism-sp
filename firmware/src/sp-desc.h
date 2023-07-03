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
#ifndef _SP_DESC_H_
#define _SP_DESC_H_

typedef uint32_t gem_rx_dma_desc_word_type;
typedef uint32_t gem_tx_dma_desc_word_type;

struct sp_desc_gem_queue {
	struct sp_gem_queue base;

	gem_rx_dma_desc_word_type *dma_desc_base;
	gem_rx_dma_desc_word_type *cur_dma_desc_addr;
	void *prefetch_addr;
	int prefetch_primed;
};

struct sp_desc_gem_rx_queue {
	struct sp_desc_gem_queue q;
};

struct sp_desc_gem_tx_queue {
	struct sp_desc_gem_queue q;
	// Keeps the address of the last start-of-frame descriptor.
	// We need this to set the valid bit of this (and only this)
	// descriptor when we're done with the packet.
	gem_rx_dma_desc_word_type *saved_cur_dma_desc_addr;
	gem_rx_dma_desc_word_type saved_dma_desc_1;
};

void dump_tx_descs(int q);

extern struct sp_desc_gem_rx_queue rx_queues[NQUEUES];
extern struct sp_desc_gem_tx_queue tx_queues[NQUEUES];

#endif
