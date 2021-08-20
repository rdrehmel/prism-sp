/*
 * Copyright (c) 2021 Robert Drehmel
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

/*
 * This file defines the API for the DMA stuff
 */
#define SP_FUNCT7_RX_META_NELEMS		"0x0"
#define SP_FUNCT7_RX_META_POP			"0x1"
#define SP_FUNCT7_RX_DATA_SKIP			"0x4"
#define SP_FUNCT7_RX_DATA_DMA_START		"0x5"
#define SP_FUNCT7_RX_DATA_DMA_STATUS	"0x6"

#define SP_FUNCT7_TX_META_NFREE			"0x8"
#define SP_FUNCT7_TX_META_PUSH			"0x9"
#define SP_FUNCT7_TX_DATA_SKIP			"0xc"
#define SP_FUNCT7_TX_DATA_DMA_START		"0xd"
#define SP_FUNCT7_TX_DATA_DMA_STATUS	"0xe"

#define SP_FUNCT7_LOAD_REG				"0x10"
#define SP_FUNCT7_STORE_REG				"0x11"
#define SP_FUNCT7_PULSE					"0x1f"

// A custom instruction without arguments
#define EMIT_INSN_000(funct7) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, 0, " funct7 ", x0, x0, x0\n" \
	: : )

// A custom instruction
// 0 arguments
// 1 return value
#define EMIT_INSN_100(funct7, rd) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, 0, " funct7 ", %[_rd], x0, x0\n" \
		: [_rd] "=r" (rd) \
		: \
	)

// A custom instruction with two arguments
#define EMIT_INSN_011(funct7, rs1, rs2) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, 0, " funct7 ", x0, %[_rs1], %[_rs2]\n" \
	: \
	: [_rs1] "r" (rs1), [_rs2] "r" (rs2) \
	)

#define EMIT_INSN_010(funct7, rs1) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, 0, " funct7 ", x0, %[_rs1], x0\n" \
	: \
	: [_rs1] "r" (rs1) \
	)

// A custom instruction with one argument and a return value
#define EMIT_INSN_110(funct7, rd, rs1) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, 0, " funct7 ", %[_rd], %[_rs1], x0\n" \
	: [_rd] "=r" (rd) \
	: [_rs1] "r" (rs1) \
	)

// A custom instruction with two arguments and a return value
#define EMIT_INSN_111(funct7, rd, rs1, rs2) \
	__asm__ __volatile__( \
		".insn r CUSTOM_0, 0, " funct7 ", %[_rd], %[_rs1], %[_rs2]\n" \
	: [_rd] "=r" (rd) \
	: [_rs1] "r" (rs1), [_rs2] "r" (rs2) \
	)

/*
 * This function loads a word from the meta FIFO of channel nchan.
 */
static inline uint32_t
sp_rx_meta_nelems()
{
	uint32_t x;

	EMIT_INSN_100(SP_FUNCT7_RX_META_NELEMS, x);
	return x;
}

static inline uint32_t
sp_rx_meta_pop_uint32()
{
	uint32_t x;

	EMIT_INSN_100(SP_FUNCT7_RX_META_POP, x);
	return x;
}

static inline void
sp_rx_data_skip(uint32_t length)
{
	EMIT_INSN_010(SP_FUNCT7_RX_DATA_SKIP, length);
}

static inline void
sp_rx_data_dma_start(uint32_t addr, uint32_t length)
{
	EMIT_INSN_011(SP_FUNCT7_RX_DATA_DMA_START, addr, length);
}

static inline uint32_t
sp_rx_data_dma_status()
{
	uint32_t x;
	EMIT_INSN_100(SP_FUNCT7_RX_DATA_DMA_START, x);
	return x;
}

static inline uint32_t
sp_tx_meta_nfree()
{
	uint32_t x;

	EMIT_INSN_100(SP_FUNCT7_TX_META_NFREE, x);
	return x;
}

static inline void
sp_tx_meta_push_uint32(uint32_t x)
{
	EMIT_INSN_010(SP_FUNCT7_TX_META_PUSH, x);
}

static inline void
sp_tx_data_dma_start(uint32_t addr, uint32_t length)
{
	EMIT_INSN_011(SP_FUNCT7_TX_DATA_DMA_START, addr, length);
}

static inline uint32_t
sp_tx_data_dma_status()
{
	uint32_t x;
	EMIT_INSN_100(SP_FUNCT7_TX_DATA_DMA_START, x);
	return x;
}

static inline uint32_t
sp_load_reg(int i)
{
	uint32_t x;
	EMIT_INSN_110(SP_FUNCT7_LOAD_REG, x, i);
	return i;
}

static inline void
sp_store_reg(int i, uint32_t x)
{
	EMIT_INSN_011(SP_FUNCT7_STORE_REG, i, x);
}

static inline void
sp_irq()
{
	EMIT_INSN_000(SP_FUNCT7_PULSE);
}

#endif
