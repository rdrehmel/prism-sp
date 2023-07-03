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
import taiga_config::*;
import taiga_types::*;
import sp_unit_config::*;

module prism_sp_duo_rx_top #(
	parameter int IBRAM_SIZE = 2**15,
	parameter int DBRAM_SIZE = 2**15,
	parameter int ACPBRAM_SIZE = 2*64*8,

	parameter int RX_DATA_FIFO_SIZE,
	parameter int RX_DATA_FIFO_WIDTH
)
(
	input wire clock,
	input wire resetn,

	output wire gem_irq,
	output wire gem_irq_rx,

	axi_lite_write_address_channel.slave s_axil_aw,
	axi_lite_write_channel.slave s_axil_w,
	axi_lite_write_response_channel.slave s_axil_b,
	axi_lite_read_address_channel.slave s_axil_ar,
	axi_lite_read_channel.slave s_axil_r,

	axi_interface.master m_axi_io,

	axi_write_address_channel.master m_axi_acp_aw,
	axi_write_channel.master m_axi_acp_w,
	axi_write_response_channel.master m_axi_acp_b,
	axi_read_address_channel.master m_axi_acp_ar,
	axi_read_channel.master m_axi_acp_r,

	axi_write_address_channel.master m_axi_dma_aw,
	axi_write_channel.master m_axi_dma_w,
	axi_write_response_channel.master m_axi_dma_b,

	gem_rx_interface.slave gem_rx
);

wire logic queue_0_rxdone;
wire logic queue_1_rxdone;

// This is tied to zero for now.
// Currently, we rely on the GEM device itself to set the default ISR for
// non-RX and non-TX complete IRQs.
assign gem_irq = 1'b0;
assign gem_irq_rx = queue_0_rxdone | queue_1_rxdone;

gem_tx_interface dummy_gem_tx();

wire logic [3:0] dma_axi_axcache;
assign m_axi_dma_aw.awcache = dma_axi_axcache;
axi_read_address_channel dummy_m_axi_dma_ar();
axi_read_channel dummy_m_axi_dma_r();

prism_sp_duo_xx_top #(
	.IBRAM_SIZE(IBRAM_SIZE),
	.DBRAM_SIZE(DBRAM_SIZE),
	.ACPBRAM_SIZE(ACPBRAM_SIZE),
	.RX_DATA_FIFO_SIZE(RX_DATA_FIFO_SIZE),
	.RX_DATA_FIFO_WIDTH(RX_DATA_FIFO_WIDTH),
	.USE_SP_UNIT_RX(1)
) prism_sp_duo_xx_top_rx(
	.clock(clock),
	.resetn(resetn),

	.s_axil_aw,
	.s_axil_w,
	.s_axil_b,
	.s_axil_ar,
	.s_axil_r,

	.m_axi_io,

	.m_axi_acp_aw,
	.m_axi_acp_w,
	.m_axi_acp_b,
	.m_axi_acp_ar,
	.m_axi_acp_r,

	.dma_axi_axcache,
	.m_axi_dma_aw,
	.m_axi_dma_w,
	.m_axi_dma_b,
	.m_axi_dma_ar(dummy_m_axi_dma_ar),
	.m_axi_dma_r(dummy_m_axi_dma_r),

	.gem_rx(gem_rx),
	.gem_tx(dummy_gem_tx),
	.queue_0_rxdone,
	.queue_1_rxdone
);

endmodule
