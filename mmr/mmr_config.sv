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
package mmr_config;

// XXX Doesn't really belong here.
localparam int NGEMQUEUES = 2;

typedef enum int {
	MMR_RW_REGN_CONTROL
} mmr_rw_n;

typedef enum int {
	MMR_R_REGN_IO_AXI_AXCACHE,
	MMR_R_REGN_DMA_AXI_AXCACHE,
	MMR_R_REGN_RESERVED0,
	MMR_R_REGN_RX_DMA_DESC_BASE_0,
	MMR_R_REGN_RX_DMA_DESC_BASE_1,
	MMR_R_REGN_TX_DMA_DESC_BASE_0,
	MMR_R_REGN_TX_DMA_DESC_BASE_1,
	MMR_R_REGN_RX_DATA_FIFO_SIZE,
	MMR_R_REGN_RX_DATA_FIFO_WIDTH,
	MMR_R_REGN_TX_DATA_FIFO_SIZE,
	MMR_R_REGN_TX_DATA_FIFO_WIDTH
} mmr_r_n;

localparam int SIZEOF_REG = 4;
// 10 = 2**10/1024 bytes of MMR addresses
localparam int MMR_RANGE_WIDTH = 10;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_CONTROL			= 10'h004;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_STATUS			= 10'h008;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_BRAM_ADDR			= 10'h010;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_BRAM_DATA			= 10'h014;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_IO_AXI_AXCACHE	= 10'h020;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_DMA_AXI_AXCACHE	= 10'h024;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_RESERVED0			= 10'h028;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_RX_DMA_DESC_BASE	= 10'h040;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_TX_DMA_DESC_BASE	= 10'h080;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_IER_BASE			= 10'h100;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_IDR_BASE			= 10'h120;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_IMR_BASE			= 10'h140;
localparam logic [MMR_RANGE_WIDTH-1:0] REGOFF_ISR_BASE			= 10'h160;

localparam int MMR_RW_NREGS = 1;
localparam int MMR_R_NREGS = 11;
localparam int MMR_R_BITN = 8;

endpackage
