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
package sp_unit_config;

typedef enum logic [4:0] {
	SP_FUNC7_RX_META_NELEMS		= 5'b00000,
	SP_FUNC7_RX_META_POP		= 5'b00001,
	SP_FUNC7_RX_META_EMPTY		= 5'b00010,
	SP_FUNC7_RX_DATA_SKIP		= 5'b00100,
	SP_FUNC7_RX_DATA_DMA_START	= 5'b00101,
	SP_FUNC7_RX_DATA_DMA_STATUS	= 5'b00110,

	SP_FUNC7_TX_META_NFREE		= 5'b01000,
	SP_FUNC7_TX_META_PUSH		= 5'b01001,
	SP_FUNC7_TX_META_FULL		= 5'b01010,
	SP_FUNC7_TX_DATA_COUNT		= 5'b01100,
	SP_FUNC7_TX_DATA_SKIP		= 5'b01101,
	SP_FUNC7_TX_DATA_DMA_START	= 5'b01110,
	SP_FUNC7_TX_DATA_DMA_STATUS	= 5'b01111,

	SP_FUNC7_LOAD_REG			= 5'b10000,
	SP_FUNC7_STORE_REG			= 5'b10001,
	SP_FUNC7_INTR				= 5'b10010,

	SP_FUNC7_ACP_READ_START			= 5'b11000,
	SP_FUNC7_ACP_READ_STATUS		= 5'b11001,
	SP_FUNC7_ACP_WRITE_START		= 5'b11010,
	SP_FUNC7_ACP_WRITE_STATUS		= 5'b11011,
	SP_FUNC7_ACP_SET_LOCAL_WSTRB	= 5'b11100,
	SP_FUNC7_ACP_SET_REMOTE_WSTRB	= 5'b11101
} sp_func7_t;

localparam int CMD_RX_META_NELEMS		= 0;
localparam int CMD_RX_META_POP			= CMD_RX_META_NELEMS + 1;
localparam int CMD_RX_META_EMPTY		= CMD_RX_META_POP + 1;
localparam int CMD_RX_DATA_SKIP			= CMD_RX_META_EMPTY + 1;
localparam int CMD_RX_DATA_DMA_START	= CMD_RX_DATA_SKIP + 1;
localparam int CMD_RX_DATA_DMA_STATUS	= CMD_RX_DATA_DMA_START + 1;
localparam int CMD_RX_FIRST				= CMD_RX_META_NELEMS;
localparam int CMD_RX_LAST				= CMD_RX_DATA_DMA_STATUS;

localparam int CMD_TX_META_NFREE		= 0;
localparam int CMD_TX_META_PUSH			= CMD_TX_META_NFREE + 1;
localparam int CMD_TX_META_FULL			= CMD_TX_META_PUSH + 1;
localparam int CMD_TX_DATA_COUNT		= CMD_TX_META_FULL + 1;
localparam int CMD_TX_DATA_SKIP			= CMD_TX_DATA_COUNT + 1;
localparam int CMD_TX_DATA_DMA_START	= CMD_TX_DATA_SKIP + 1;
localparam int CMD_TX_DATA_DMA_STATUS	= CMD_TX_DATA_DMA_START + 1;
localparam int CMD_TX_FIRST				= CMD_TX_META_NFREE;
localparam int CMD_TX_LAST				= CMD_TX_DATA_DMA_STATUS;

localparam int CMD_LOAD_REG				= 0;
localparam int CMD_STORE_REG			= CMD_LOAD_REG + 1;
localparam int CMD_INTR					= CMD_STORE_REG + 1;
localparam int CMD_COMMON_FIRST			= CMD_LOAD_REG;
localparam int CMD_COMMON_LAST			= CMD_INTR;

localparam int CMD_ACP_READ_START		= 0;
localparam int CMD_ACP_READ_STATUS		= CMD_ACP_READ_START + 1;
localparam int CMD_ACP_WRITE_START		= CMD_ACP_READ_STATUS + 1;
localparam int CMD_ACP_WRITE_STATUS		= CMD_ACP_WRITE_START + 1;
localparam int CMD_ACP_SET_LOCAL_WSTRB	= CMD_ACP_WRITE_STATUS + 1;
localparam int CMD_ACP_SET_REMOTE_WSTRB	= CMD_ACP_SET_LOCAL_WSTRB + 1;
localparam int CMD_ACP_FIRST			= CMD_ACP_READ_START;
localparam int CMD_ACP_LAST				= CMD_ACP_SET_REMOTE_WSTRB;

localparam int SP_UNIT_COMMON_NCMDS = CMD_COMMON_LAST - CMD_COMMON_FIRST + 1;
localparam int SP_UNIT_RX_NCMDS = CMD_RX_LAST - CMD_RX_FIRST + 1;
localparam int SP_UNIT_TX_NCMDS = CMD_TX_LAST - CMD_TX_FIRST + 1;
localparam int SP_UNIT_ACP_NCMDS = CMD_ACP_LAST - CMD_ACP_FIRST + 1;

localparam GEM_RXDONE_BITN		= 1;
localparam GEM_TXDONE_BITN		= 7;

endpackage
