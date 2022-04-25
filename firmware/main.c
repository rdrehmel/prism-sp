/*
 * Copyright (c) 2021,2022 Robert Drehmel
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

#include "csr.h"
#include "sp.h"
#include "gem.h"

#ifndef UINT32_MIN
#define UINT32_MIN		0x00000000
#endif
#ifndef UINT32_MAX
#define UINT32_MAX		0xffffffff
#endif

#define NQUEUES					2
#define DEBUG
//#define DMA_PROF_TX
//#define DMA_PROF_RX
#define DMA_PROF_MIN_PACKET_SIZE	60
#define DMA_PROF_MAX_PACKET_SIZE	1500
#define DMA_PROF_NSAMPLES			10000

typedef uint32_t gem_rx_dma_desc_type;
typedef uint32_t gem_tx_dma_desc_type;
typedef uint32_t gem_rx_meta_desc_type;
typedef uint32_t gem_tx_meta_desc_type;
typedef uint32_t dma_addr_t;

struct gem_queue {
	gem_rx_dma_desc_type *rx_dma_desc_base;
	gem_rx_dma_desc_type *cur_rx_dma_desc_addr;
	gem_tx_dma_desc_type *tx_dma_desc_base;
	gem_tx_dma_desc_type *cur_tx_dma_desc_addr;
} queues[NQUEUES];

struct sp_config {
	int rx_data_fifo_size;
	int rx_data_fifo_width;
	int tx_data_fifo_size;
	int tx_data_fifo_width;
} config;

void rx(int);
int tx(int);

#if defined(DMA_PROF_RX) || defined(DMA_PROF_TX)
struct dma_prof_result {
	uint32_t min;
	uint32_t max;
	uint64_t total;
	float avg;
};
#endif
#ifdef DMA_PROF_RX
int dma_prof_rx_cur_packet_size = DMA_PROF_MIN_PACKET_SIZE;
int dma_prof_rx_cur_samplen = 0;
struct dma_prof_result dma_prof_result_rx;
#endif
#ifdef DMA_PROF_TX
int dma_prof_tx_cur_packet_size = DMA_PROF_MIN_PACKET_SIZE;
int dma_prof_tx_cur_samplen = 0;
struct dma_prof_result dma_prof_result_tx;
#endif

#if defined(DMA_PROF_RX) || defined(DMA_PROF_TX)
void
dma_prof_result_reset(struct dma_prof_result *result)
{
	result->min = UINT32_MAX;
	result->max = UINT32_MIN;
	result->total = 0;
	result->avg;
}
void
dma_prof_result_eval(struct dma_prof_result *result, uint32_t x)
{
	if (result->min > x)
		result->min = x;
	if (result->max < x)
		result->max = x;
	result->total += x;
}
void
dma_prof_result_eval_final(struct dma_prof_result *result)
{
	result->avg = (float)result->total / DMA_PROF_NSAMPLES;
}
void
dma_prof_result_print(struct dma_prof_result *result)
{
	printf("%d %d %0.10f\n", result->min, result->max, result->avg);
}
#endif

uint32_t
gem_read_reg(const volatile void *base, int offset)
{
	return *(volatile uint32_t *)(base + offset);
}

void
gem_write_reg(volatile void *base, int offset, uint32_t x)
{
	*(volatile uint32_t *)(base + offset) = x;
}

uint32_t
gem_tx_dma_desc0_get_addr(gem_tx_dma_desc_type desc)
{
	return desc;
}

int
gem_tx_dma_desc1_get_length(gem_tx_dma_desc_type desc)
{
	// 13:0 is the buffer length
	return desc & 0x3fff;
}

uint32_t
gem_rx_dma_desc0_get_addr(gem_rx_dma_desc_type desc)
{
	return desc & ~(uint32_t)0x3;
}

int
gem_rx_dma_desc1_get_length(gem_rx_dma_desc_type desc)
{
	return desc & 0x1fff;
}

int
gem_rx_meta_desc_get_length(gem_rx_meta_desc_type desc)
{
	return gem_rx_dma_desc1_get_length(desc);
}

void
gem_tx_done(int q)
{
	sp_intr(q, 1 << MACB_TXDONE_BITN);
}

void
gem_rx_done(int q)
{
	sp_intr(q, 1 << MACB_RXDONE_BITN);
}

/*
 * Called when triggered by the GEM FIFO interface.
 */
void
rx(int q)
{
	struct gem_queue *queue = &queues[q];

	// Get next descriptor from DRAM
	gem_rx_dma_desc_type *dma_descp = queue->cur_rx_dma_desc_addr;
	gem_rx_dma_desc_type dma_desc_0 = *(dma_descp + 0);
	if (dma_desc_0 & (1 << GEM_RX_DD0_VALID_BITN)) {
		//printf("RX: There are no free descriptors!\n");
		return;
	}
	// XXX We currently only support 32-bit addresses.
#ifdef GEM_64BIT_DESC
	gem_rx_dma_desc_type dma_desc_0msb = *(dma_descp + 2);
#endif
	gem_rx_dma_desc_type dma_desc_1 = *(dma_descp + 1);

	// Get meta information from BRAM
	gem_rx_meta_desc_type meta_desc = sp_rx_meta_pop_uint32();
#ifdef DEBUG
	printf("rx meta: 0x%08x\n", meta_desc);
#endif

	// Do nothing with the data just received
	// ...
	// Could skip, could modify.

	// Get the destination of the buffer in DRAM
	dma_addr_t data_addr = gem_rx_dma_desc0_get_addr(dma_desc_0);
	// Get length from BRAM
	int data_length = gem_rx_meta_desc_get_length(meta_desc);
#ifdef DEBUG
	printf("RX: [%p] 0:0x%08x 1:0x%08x addr=0x%08x len=%d meta=0x%08x\n",
		dma_descp, dma_desc_0, dma_desc_1, data_addr, data_length, meta_desc);
#endif

#ifdef DMA_PROF_RX
	uint64_t cycle_start;
	uint64_t cycle_stop;
	uint64_t time_start;
	uint64_t time_stop;
	cycle_start = csr_read_cycle();
	time_start = csr_read_time();
#endif
	sp_rx_data_dma_start(data_addr, data_length);
	int niters;
	for (niters = 0;; niters++) {
		uint32_t status = sp_rx_data_dma_status();
		if (status == 0) {
#ifdef DMA_PROF_RX
			cycle_stop = csr_read_cycle();
			time_stop = csr_read_time();
#endif
			break;
		}
	}
#ifdef DMA_PROF_RX
	if (dma_prof_rx_cur_packet_size == data_length) {
		dma_prof_result_eval(&dma_prof_result_rx, cycle_stop - cycle_start);
		if (dma_prof_rx_cur_samplen == DMA_PROF_NSAMPLES - 1) {
			dma_prof_result_eval_final(&dma_prof_result_rx);
			printf("%d ", dma_prof_rx_cur_packet_size);
			dma_prof_result_print(&dma_prof_result_rx);
			dma_prof_result_reset(&dma_prof_result_rx);
			dma_prof_rx_cur_samplen = 0;
			if (dma_prof_rx_cur_packet_size == DMA_PROF_MAX_PACKET_SIZE) {
				printf("--------\n");
			}
			dma_prof_rx_cur_packet_size += 4;
		}
		else {
			dma_prof_rx_cur_samplen++;
		}
	}
#ifdef DEBUG
	printf("Iterations=%d\n", niters);
	printf("Cycle_start=%" PRIu64 "\n", cycle_start);
	printf("Cycle_stop=%" PRIu64 "\n", cycle_stop);
	printf("time_start=%" PRIu64 "\n", time_start);
	printf("time_stop=%" PRIu64 "\n", time_stop);
	printf("RX DMA took %" PRIu64 " cycles\n", cycle_stop - cycle_start);
	printf("RX DMA took %" PRIu64 " times\n", time_stop - time_start);
#endif
#endif

	// Set all the other parameters.
	*(dma_descp + 1) = meta_desc;
	// Update DRAM descriptor to be valid
	dma_desc_0 |= 1 << GEM_RX_DD0_VALID_BITN;
	*(dma_descp + 0) = dma_desc_0;
#ifdef DEBUG_VERBOSE
	printf("Value 0x%08x written to %p\n", dma_desc_0, dma_descp);
	printf("Value 0x%08x written to %p\n", meta_desc, dma_descp + 1);
#endif

	// On to the next descriptor
	if (dma_desc_0 & (1 << GEM_RX_DD0_WRAP_BITN)) {
		queue->cur_rx_dma_desc_addr = queue->rx_dma_desc_base;
	}
	else {
		queue->cur_rx_dma_desc_addr += 2;
	}

	// Send the RX done interrupt
	gem_rx_done(q);
}

void
dump_tx_descs(int q)
{
	struct gem_queue *queue = &queues[q];
	gem_tx_dma_desc_type *dma_descp = (gem_tx_dma_desc_type *)queue->tx_dma_desc_base;

	for (;;) {
		for (int i = 0; i < 7; i++) {
			gem_tx_dma_desc_type dma_desc_0 = *(dma_descp + 0);
			gem_tx_dma_desc_type dma_desc_1 = *(dma_descp + 1);

			printf("%s(0x%08x)[0x%08x|0x%08x]  ",
				dma_descp == queue->cur_tx_dma_desc_addr ? "*" : " ",
				dma_descp, dma_desc_0, dma_desc_1
			);

			if (dma_desc_1 & (1 << GEM_TX_DD1_WRAP_BITN)) {
				printf("\n");
				return;
			}
			dma_descp += 2;
		}
		printf("\n");
	}
}

/*
 * Called when triggered by MMIO.
 */
int
tx(int q)
{
	struct gem_queue *queue = &queues[q];
	gem_tx_dma_desc_type *packet_dma_descp;
	gem_tx_dma_desc_type packet_dma_desc_1;
	int packet_length = 0;
	int ntxdescs = 0;
	bool no_crc;

	for (;;) {
		// Get the next descriptor from DRAM
		gem_tx_dma_desc_type *dma_descp = queue->cur_tx_dma_desc_addr;
		gem_tx_dma_desc_type dma_desc_0 = *(dma_descp + 0);
		gem_tx_dma_desc_type dma_desc_1 = *(dma_descp + 1);

		if (dma_desc_1 & (1 << GEM_TX_DD1_VALID_BITN)) {
#ifdef DEBUG
			printf("TX: [%p] BUSY\n", dma_descp);
#endif
			break;
		}
		ntxdescs++;

		// If this is the first descriptor of this packet.
		if (packet_length == 0) {
			// Save the pointer to the first descriptor of the packet.
			packet_dma_descp = dma_descp;
			packet_dma_desc_1 = dma_desc_1;
			no_crc = (dma_desc_1 & (1 << GEM_TX_DD1_NOCRC_BITN)) != 0;
		}

		// Get the DRAM address and length of the payload buffer
		dma_addr_t data_addr = gem_tx_dma_desc0_get_addr(dma_desc_0);
		int data_length = gem_tx_dma_desc1_get_length(dma_desc_1);

#ifdef DEBUG
		printf("%sTX: [%p] 0:0x%08x 1:0x%08x addr=0x%08x len=%d\n",
			packet_length == 0 ? "****" : "    ",
			dma_descp, dma_desc_0, dma_desc_1, data_addr, data_length);
#endif

		bool eof = (dma_desc_1 & (1 << GEM_TX_DD1_EOF_BITN)) != 0;
#ifdef DMA_PROF_TX
		uint64_t cycle_start;
		uint64_t cycle_stop;
		uint64_t time_start;
		uint64_t time_stop;
		cycle_start = csr_read_cycle();
		time_start = csr_read_time();
#endif
		uint32_t count;
		for (;;) {
			count = sp_tx_data_count();
			if (config.tx_data_fifo_size - count >= data_length)
				break;
		}

		sp_tx_data_dma_start(data_addr, (uint32_t)!eof << 31 | data_length);
		int niters;
		for (niters = 0;; niters++) {
			uint32_t status = sp_tx_data_dma_status();
			if (status == 0) {
#ifdef DMA_PROF_TX
				cycle_stop = csr_read_cycle();
				time_stop = csr_read_time();
#endif
				break;
			}
		}

#ifdef DMA_PROF_TX
	if (dma_prof_tx_cur_packet_size == data_length) {
		dma_prof_result_eval(&dma_prof_result_tx, cycle_stop - cycle_start);
		if (dma_prof_tx_cur_samplen == DMA_PROF_NSAMPLES) {
			dma_prof_result_eval_final(&dma_prof_result_tx);
			printf("%d ", dma_prof_tx_cur_packet_size);
			dma_prof_result_print(&dma_prof_result_tx);
			dma_prof_result_reset(&dma_prof_result_tx);
			dma_prof_tx_cur_samplen = 0;
			if (dma_prof_tx_cur_packet_size == DMA_PROF_MAX_PACKET_SIZE) {
				printf("--------\n");
			}
			dma_prof_tx_cur_packet_size += 4;
		}
		else {
			dma_prof_tx_cur_samplen++;
		}
	}
#ifdef DEBUG
	printf("Iterations=%d\n", niters);
	printf("Cycle_start=%" PRIu64 "\n", cycle_start);
	printf("Cycle_stop=%" PRIu64 "\n", cycle_stop);
	printf("time_start=%" PRIu64 "\n", time_start);
	printf("time_stop=%" PRIu64 "\n", time_stop);
	printf("TX DMA took %" PRIu64 " cycles\n", cycle_stop - cycle_start);
	printf("TX DMA took %" PRIu64 " times\n", time_stop - time_start);
#endif
#endif

		packet_length += data_length;

		// Do nothing with the data just read
		// ...
		// Could skip, could modify.

		// On to the next descriptor in any case.
		if (dma_desc_1 & (1 << GEM_TX_DD1_WRAP_BITN)) {
			queue->cur_tx_dma_desc_addr = queues[q].tx_dma_desc_base;
		}
		else {
			queue->cur_tx_dma_desc_addr += 2;
		}

		if (eof) {
			// Mark the first descriptor of this packet as usable by the driver
			// Note that only the first descriptor is set to valid.
			packet_dma_desc_1 |= (uint32_t)1 << GEM_TX_DD1_VALID_BITN;
			*(packet_dma_descp + 1) = packet_dma_desc_1;

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

extern void uart_init();

void
start()
{
	const int ALL_QUEUE_BITS = (1 << NQUEUES) - 1;
	uint32_t x;
	int do_tx = 0;

	for (;;) {
		x = sp_rx_meta_empty();
		if (!x) {
			// Put all the received packets into the first queue.
			rx(0);
		}

		if (do_tx != ALL_QUEUE_BITS) {
			x = sp_load_reg(SP_REGN_CONTROL);
			if (x & (1 << SP_CONTROL_START_TX_BITN)) {
				sp_store_reg(SP_REGN_CONTROL, x ^ (1 << SP_CONTROL_START_TX_BITN));
				do_tx = ALL_QUEUE_BITS;
			}
		}
		for (int q = 0; q < NQUEUES; q++) {
			if (do_tx & (1 << q)) {
				if (tx(q) == 0) {
					do_tx ^= 1 << q;
				}
			}
		}
	}
}

int
main()
{
	uint32_t x;

	uart_init();

	printf("----\n");
	printf("Stream Processor/GEM firmware version 0.57\n");
	printf("----\n");
	printf("Waiting for start signal.\n");

	uint32_t enable_bits = (1 << SP_CONTROL_ENABLE_RX_BITN) | (1 << SP_CONTROL_ENABLE_TX_BITN);
	do {
		x = sp_load_reg(SP_REGN_CONTROL);
	} while ((x & enable_bits) != enable_bits);
	printf("Received start signal.\n");
	printf("Fetching private DMA configuration.\n");

	queues[0].rx_dma_desc_base =
		(gem_rx_dma_desc_type *)sp_load_reg(SP_REGN_RX_DMA_DESC_BASE_0);
	queues[0].cur_rx_dma_desc_addr = queues[0].rx_dma_desc_base;
	queues[1].rx_dma_desc_base =
		(gem_rx_dma_desc_type *)sp_load_reg(SP_REGN_RX_DMA_DESC_BASE_1);
	queues[1].cur_rx_dma_desc_addr = queues[1].rx_dma_desc_base;

	printf("Descriptor base of RX queue 0 is at %p\n", queues[0].rx_dma_desc_base);
	printf("Descriptor base of RX queue 1 is at %p\n", queues[1].rx_dma_desc_base);

	queues[0].tx_dma_desc_base =
		(gem_tx_dma_desc_type *)sp_load_reg(SP_REGN_TX_DMA_DESC_BASE_0);
	queues[0].cur_tx_dma_desc_addr = queues[0].tx_dma_desc_base;
	queues[1].tx_dma_desc_base =
		(gem_tx_dma_desc_type *)sp_load_reg(SP_REGN_TX_DMA_DESC_BASE_1);
	queues[1].cur_tx_dma_desc_addr = queues[1].tx_dma_desc_base;

	printf("Descriptor base of TX queue 0 is at %p\n", queues[0].tx_dma_desc_base);
	printf("Descriptor base of TX queue 1 is at %p\n", queues[1].tx_dma_desc_base);

	config.rx_data_fifo_size = sp_load_reg(SP_REGN_RX_DATA_FIFO_SIZE);
	config.rx_data_fifo_width = sp_load_reg(SP_REGN_RX_DATA_FIFO_WIDTH);
	printf("RX data FIFO:\n");
	printf("  Width: %10d\n", config.rx_data_fifo_width);
	printf("  Size : %10d\n", config.rx_data_fifo_size);

	config.tx_data_fifo_size = sp_load_reg(SP_REGN_TX_DATA_FIFO_SIZE);
	config.tx_data_fifo_width = sp_load_reg(SP_REGN_TX_DATA_FIFO_WIDTH);
	printf("TX data FIFO:\n");
	printf("  Width: %10d\n", config.tx_data_fifo_width);
	printf("  Size : %10d\n", config.tx_data_fifo_size);

#ifdef DMA_PROF_RX
	dma_prof_result_reset(&dma_prof_result_rx);
#endif
#ifdef DMA_PROF_TX
	dma_prof_result_reset(&dma_prof_result_tx);
#endif
#if defined(DMA_PROF_RX) || defined(DMA_PROF_TX)
	printf("#nsamples=%d\n", DMA_PROF_NSAMPLES);
	printf("packet_size min max avg\n");
#endif

	start();
	printf("Done.\n");

	return 0;
}
