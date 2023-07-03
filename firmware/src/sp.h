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
#ifndef _SP_H_
#define _SP_H_

#include <stdint.h>
#include <stdbool.h>

#ifndef UINT32_MIN
#define UINT32_MIN		0x00000000
#endif
#ifndef UINT32_MAX
#define UINT32_MAX		0xffffffff
#endif

#define NQUEUES					2
/*
 * These identifiers are found in the funct7 field of the instruction.
 * The SP unit decodes them to find out which instruction to execute.
 */
#define SP_FUNCT7_RX_META_NELEMS		"0x0"
#define SP_FUNCT7_RX_META_POP			"0x1"
#define SP_FUNCT7_RX_META_EMPTY			"0x2"
#define SP_FUNCT7_RX_DATA_SKIP			"0x4"
#define SP_FUNCT7_RX_DATA_DMA_START		"0x5"
#define SP_FUNCT7_RX_DATA_DMA_STATUS	"0x6"

#define SP_FUNCT7_TX_META_NFREE			"0x8"
#define SP_FUNCT7_TX_META_PUSH			"0x9"
#define SP_FUNCT7_TX_META_FULL			"0xa"
#define SP_FUNCT7_TX_DATA_COUNT			"0xc"
#define SP_FUNCT7_TX_DATA_SKIP			"0xd"
#define SP_FUNCT7_TX_DATA_DMA_START		"0xe"
#define SP_FUNCT7_TX_DATA_DMA_STATUS	"0xf"

#define SP_FUNCT7_LOAD_REG				"0x10"
#define SP_FUNCT7_STORE_REG				"0x11"
#define SP_FUNCT7_INTR					"0x12"

#define SP_FUNCT7_ACP_READ_START		"0x18"
#define SP_FUNCT7_ACP_READ_STATUS		"0x19"
#define SP_FUNCT7_ACP_WRITE_START		"0x1a"
#define SP_FUNCT7_ACP_WRITE_STATUS		"0x1b"
#define SP_FUNCT7_ACP_SET_LOCAL_WSTRB	"0x1c"
#define SP_FUNCT7_ACP_SET_REMOTE_WSTRB	"0x1d"

// This bit marks read-only registers
#define SP_MMR_R_BITN					8

#define SP_REGN_CONTROL					0

enum {
	SP_MMR_R_REGN_IO_AXI_AXCACHE,
	SP_MMR_R_REGN_DMA_AXI_AXCACHE,
	SP_MMR_R_REGN_RESERVED_0,
	SP_MMR_R_REGN_RX_DMA_DESC_BASE_0,
	SP_MMR_R_REGN_RX_DMA_DESC_BASE_1,
	SP_MMR_R_REGN_TX_DMA_DESC_BASE_0,
	SP_MMR_R_REGN_TX_DMA_DESC_BASE_1,
	SP_MMR_R_REGN_RX_DATA_FIFO_SIZE,
	SP_MMR_R_REGN_RX_DATA_FIFO_WIDTH,
	SP_MMR_R_REGN_TX_DATA_FIFO_SIZE,
	SP_MMR_R_REGN_TX_DATA_FIFO_WIDTH
};
#define SP_REGN_IO_AXI_AXCACHE			(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_IO_AXI_AXCACHE)
#define SP_REGN_DMA_AXI_AXCACHE			(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_DMA_AXI_AXCACHE)
#define SP_REGN_RX_DMA_DESC_BASE_0		(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_RX_DMA_DESC_BASE_0)
#define SP_REGN_RX_DMA_DESC_BASE_1		(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_RX_DMA_DESC_BASE_1)
#define SP_REGN_TX_DMA_DESC_BASE_0		(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_TX_DMA_DESC_BASE_0)
#define SP_REGN_TX_DMA_DESC_BASE_1		(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_TX_DMA_DESC_BASE_1)
#define SP_REGN_RX_DATA_FIFO_SIZE		(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_RX_DATA_FIFO_SIZE)
#define SP_REGN_RX_DATA_FIFO_WIDTH		(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_RX_DATA_FIFO_WIDTH)
#define SP_REGN_TX_DATA_FIFO_SIZE		(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_TX_DATA_FIFO_SIZE)
#define SP_REGN_TX_DATA_FIFO_WIDTH		(1 << SP_MMR_R_BITN | SP_MMR_R_REGN_TX_DATA_FIFO_WIDTH)

#define SP_CONTROL_ENABLE_RX_BITN		0
#define SP_CONTROL_ENABLE_TX_BITN		1
#define SP_CONTROL_START_TX_BITN		3

struct sp_gem_queue {
	void *scratch_addr;
};

/*
 * A custom instruction with
 * 0 arguments
 * 0 return value
 */
#define EMIT_INSN_000(funct3, funct7) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, " funct3 ", " funct7 ", x0, x0, x0\n" \
	: : )

/*
 * A custom instruction with
 * 1 argument
 * 0 return value
 */
#define EMIT_INSN_010(funct3, funct7, rs1) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, " funct3 ", " funct7 ", x0, %[_rs1], x0\n" \
	: \
	: [_rs1] "r" (rs1) \
	)

/*
 * A custom instruction with
 * 2 arguments
 * 0 return value
 */
#define EMIT_INSN_011(funct3, funct7, rs1, rs2) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, " funct3 ", " funct7 ", x0, %[_rs1], %[_rs2]\n" \
	: \
	: [_rs1] "r" (rs1), [_rs2] "r" (rs2) \
	)

/*
 * A custom instruction with
 * 0 arguments
 * 1 return value
 */
#define EMIT_INSN_100(funct3, funct7, rd) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, " funct3 ", " funct7 ", %[_rd], x0, x0\n" \
		: [_rd] "=r" (rd) \
		: \
	)

/*
 * A custom instruction with
 * 1 argument
 * 1 return value
 */
#define EMIT_INSN_110(funct3, funct7, rd, rs1) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, " funct3 ", " funct7 ", %[_rd], %[_rs1], x0\n" \
	: [_rd] "=r" (rd) \
	: [_rs1] "r" (rs1) \
	)

/*
 * A custom instruction with
 * 2 argument
 * 1 return value
 */
#define EMIT_INSN_111(funct3, funct7, rd, rs1, rs2) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, " funct3 ", " funct7 ", %[_rd], %[_rs1], %[_rs2]\n" \
	: [_rd] "=r" (rd) \
	: [_rs1] "r" (rs1), [_rs2] "r" (rs2) \
	)

typedef uint32_t dma_addr_t;

struct sp_config {
	int data_fifo_size;
	int data_fifo_width;
};

/*
 * This function gives the number of elements in the RX meta FIFO.
 * Note that the hardware does not support this function currently.
 * Use sp_rx_meta_empty() instead.
 */
static inline uint32_t
sp_rx_meta_nelems(void)
{
	uint32_t x;

	EMIT_INSN_100("0", SP_FUNCT7_RX_META_NELEMS, x);
	return x;
}

/*
 * This function pops a word from the RX meta FIFO.
 */
static inline uint32_t
sp_rx_meta_pop_uint32(void)
{
	uint32_t x;

	EMIT_INSN_100("0", SP_FUNCT7_RX_META_POP, x);
	return x;
}

static inline bool
sp_rx_meta_empty(void)
{
	uint32_t x;

	EMIT_INSN_100("0", SP_FUNCT7_RX_META_EMPTY, x);
	return (bool)x;
}

static inline void
sp_rx_data_skip(uint32_t length)
{
	EMIT_INSN_010("0", SP_FUNCT7_RX_DATA_SKIP, length);
}

/*
 * This function starts the RX DMA transfer
 * (from RX data FIFO to AXI memory).
 */
static inline void
sp_rx_data_dma_start(uint32_t addr, uint32_t length)
{
	EMIT_INSN_011("0", SP_FUNCT7_RX_DATA_DMA_START, addr, length);
}

static inline uint32_t
sp_rx_data_dma_status(void)
{
	uint32_t x;

	EMIT_INSN_100("0", SP_FUNCT7_RX_DATA_DMA_STATUS, x);
	return x;
}

/*
 * Note that the hardware does not support this function currently.
 * Use sp_tx_meta_full() instead.
 */
static inline uint32_t
sp_tx_meta_nfree(void)
{
	uint32_t x;

	EMIT_INSN_100("0", SP_FUNCT7_TX_META_NFREE, x);
	return x;
}

static inline void
sp_tx_meta_push_uint32(uint32_t x)
{
	EMIT_INSN_010("0", SP_FUNCT7_TX_META_PUSH, x);
}

static inline bool
sp_tx_meta_full(void)
{
	uint32_t x;

	EMIT_INSN_100("0", SP_FUNCT7_TX_META_FULL, x);
	return (bool)x;
}

static inline uint32_t
sp_tx_data_count(void)
{
	uint32_t x;
	EMIT_INSN_100("0", SP_FUNCT7_TX_DATA_COUNT, x);
	return x;
}

static inline void
sp_tx_data_skip(uint32_t length)
{
	EMIT_INSN_010("0", SP_FUNCT7_TX_DATA_SKIP, length);
}

/*
 * This function starts the TX DMA transfer
 * (from AXI memory to TX data FIFO).
 */
static inline void
sp_tx_data_dma_start(uint32_t addr, uint32_t length)
{
	EMIT_INSN_011("0", SP_FUNCT7_TX_DATA_DMA_START, addr, length);
}

static inline uint32_t
sp_tx_data_dma_status(void)
{
	uint32_t x;
	EMIT_INSN_100("0", SP_FUNCT7_TX_DATA_DMA_STATUS, x);
	return x;
}

static inline uint32_t
sp_load_reg(int i)
{
	uint32_t x;
	EMIT_INSN_110("0", SP_FUNCT7_LOAD_REG, x, i);
	return x;
}

static inline void
sp_store_reg(int i, uint32_t x)
{
	EMIT_INSN_011("0", SP_FUNCT7_STORE_REG, i, x);
}

static inline void
sp_intr(int q, uint32_t x)
{
	EMIT_INSN_011("0", SP_FUNCT7_INTR, q, x);
}

/*
 * AXI ACP functions
 */
static inline void
sp_acp_read_start_16(uint32_t int_addr, uint32_t ext_addr)
{
	EMIT_INSN_011("0", SP_FUNCT7_ACP_READ_START, int_addr, ext_addr);
}

static inline void
sp_acp_read_start_64(uint32_t int_addr, uint32_t ext_addr)
{
	EMIT_INSN_011("1", SP_FUNCT7_ACP_READ_START, int_addr, ext_addr);
}

static inline uint32_t
sp_acp_read_status(void)
{
	uint32_t x;
	EMIT_INSN_100("0", SP_FUNCT7_ACP_READ_STATUS, x);
	return x;
}

static inline void
sp_acp_write_start_16(uint32_t int_addr, uint32_t ext_addr)
{
	EMIT_INSN_011("0", SP_FUNCT7_ACP_WRITE_START, int_addr, ext_addr);
}

static inline void
sp_acp_write_start_64(uint32_t int_addr, uint32_t ext_addr)
{
	EMIT_INSN_011("1", SP_FUNCT7_ACP_WRITE_START, int_addr, ext_addr);
}

static inline uint32_t
sp_acp_write_status(void)
{
	uint32_t x;
	EMIT_INSN_100("0", SP_FUNCT7_ACP_WRITE_STATUS, x);
	return x;
}

static inline void
sp_acp_set_local_wstrb_0(uint16_t x)
{
	EMIT_INSN_010("0", SP_FUNCT7_ACP_SET_LOCAL_WSTRB, x);
}

static inline void
sp_acp_set_local_wstrb_1(uint16_t x)
{
	EMIT_INSN_010("1", SP_FUNCT7_ACP_SET_LOCAL_WSTRB, x);
}

static inline void
sp_acp_set_local_wstrb_2(uint16_t x)
{
	EMIT_INSN_010("2", SP_FUNCT7_ACP_SET_LOCAL_WSTRB, x);
}

static inline void
sp_acp_set_local_wstrb_3(uint16_t x)
{
	EMIT_INSN_010("3", SP_FUNCT7_ACP_SET_LOCAL_WSTRB, x);
}

static inline void
sp_acp_set_remote_wstrb_0(uint16_t x)
{
	EMIT_INSN_010("0", SP_FUNCT7_ACP_SET_REMOTE_WSTRB, x);
}

static inline void
sp_acp_set_remote_wstrb_0123(uint16_t x)
{
	EMIT_INSN_010("1", SP_FUNCT7_ACP_SET_REMOTE_WSTRB, x);
}

static inline bool
sp_acp_busy(void)
{
	return sp_acp_write_status();
}

void sp_gem_queue_init(struct sp_gem_queue *, int);
void prism_hexdump(const void *na, int nbytes);
void prism_set_caching(void);
void prism_print_caching(void);

#endif
