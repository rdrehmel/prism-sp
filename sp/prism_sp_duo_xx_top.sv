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
import l2_config_and_types::*;
import sp_unit_config::*;

module prism_sp_duo_xx_top #(
	parameter int IBRAM_SIZE,
	parameter int DBRAM_SIZE,
	parameter int ACPBRAM_SIZE,

	parameter int TX_DATA_FIFO_SIZE = 0,
	parameter int TX_DATA_FIFO_WIDTH = 0,
	parameter int RX_DATA_FIFO_SIZE = 0,
	parameter int RX_DATA_FIFO_WIDTH = 0,

	parameter int USE_SP_UNIT_TX = 0,
	parameter int USE_SP_UNIT_RX = 0
)
(
	input wire logic clock,
	input wire logic resetn,

	output wire logic gem_irq,
	output wire logic gem_irq_rx,

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

	output wire logic [3:0] dma_axi_axcache,
	axi_write_address_channel.master m_axi_dma_aw,
	axi_write_channel.master m_axi_dma_w,
	axi_write_response_channel.master m_axi_dma_b,
	axi_read_address_channel.master m_axi_dma_ar,
	axi_read_channel.master m_axi_dma_r,

	gem_tx_interface.master gem_tx,
	gem_rx_interface.slave gem_rx,
	output wire logic queue_0_rxdone,
	output wire logic queue_1_rxdone,
	output wire logic queue_0_txdone,
	output wire logic queue_1_txdone
);

/*
 * Local memory interfaces
 */
localparam int IBRAM_DATA_WIDTH = 32;
localparam int IBRAM_ADDR_WIDTH = $clog2(IBRAM_SIZE / (IBRAM_DATA_WIDTH/8));
local_memory_interface instruction_bram();
local_memory_interface instruction_bram_mmr();

localparam int DBRAM_DATA_WIDTH = 32;
localparam int DBRAM_ADDR_WIDTH = $clog2(DBRAM_SIZE / (DBRAM_DATA_WIDTH/8));
local_memory_interface data_bram();
local_memory_interface data_bram_mmr();

// Port A is connected to the processor core
localparam int ACPBRAM_A_DATA_WIDTH = 32;
// Port B is connected to the ACP coprocessor
localparam int ACPBRAM_B_DATA_WIDTH = 16*8;
localparam int ACPBRAM_A_ADDR_WIDTH = $clog2(ACPBRAM_SIZE / ACPBRAM_A_DATA_WIDTH);
localparam int ACPBRAM_B_ADDR_WIDTH = $clog2(ACPBRAM_SIZE / ACPBRAM_B_DATA_WIDTH);
local_memory_interface acp_bram_a();
xpm_memory_tdpram_port_interface#(
	.ADDR_WIDTH(ACPBRAM_B_ADDR_WIDTH),
	.DATA_WIDTH(ACPBRAM_B_DATA_WIDTH)
) acp_bram_b();

// These signals are inputs to the Taiga core and are
// needed for now.
l2_requester_interface l2();
wire logic timer_interrupt;
wire logic interrupt;
wire logic cpu_reset;

wire logic [3:0] io_axi_axcache;

assign m_axi_io.awcache = io_axi_axcache;
assign m_axi_io.arcache = io_axi_axcache;

mmr_readwrite_interface #(.NREGS(MMR_RW_NREGS)) mmr_rw();
mmr_read_interface #(.NREGS(MMR_R_NREGS)) mmr_r();
mmr_intr_interface #(.N(NGEMQUEUES),.WIDTH(32)) mmr_i();

assign queue_0_rxdone = mmr_i.isr[0][GEM_RXDONE_BITN];
assign queue_1_rxdone = mmr_i.isr[1][GEM_RXDONE_BITN];
assign queue_0_txdone = mmr_i.isr[0][GEM_TXDONE_BITN];
assign queue_1_txdone = mmr_i.isr[1][GEM_TXDONE_BITN];

axi_lite_mmr #(
	.IBRAM_SIZE(IBRAM_SIZE),
	.DBRAM_SIZE(DBRAM_SIZE),
	.TX_DATA_FIFO_SIZE(TX_DATA_FIFO_SIZE),
	.TX_DATA_FIFO_WIDTH(TX_DATA_FIFO_WIDTH),
	.RX_DATA_FIFO_SIZE(RX_DATA_FIFO_SIZE),
	.RX_DATA_FIFO_WIDTH(RX_DATA_FIFO_WIDTH)
)
axi_lite_mmr_inst(
	.clock(clock),
	.reset_n(resetn),

	.axi_aw(s_axil_aw),
	.axi_w(s_axil_w),
	.axi_b(s_axil_b),
	.axi_ar(s_axil_ar),
	.axi_r(s_axil_r),

	.mmr_rw(mmr_rw),
	.mmr_r(mmr_r),
	.mmr_i(mmr_i),

	.cpu_reset(cpu_reset),
	.io_axi_axcache,
	.dma_axi_axcache,

	.instruction_bram_mmr(instruction_bram_mmr),
	.data_bram_mmr(data_bram_mmr)
);

//fifo_write_interface #(.DATA_WIDTH(RX_META_FIFO_WIDTH)) rx_data_fifo_write_mon();
//fifo_read_interface #(.DATA_WIDTH(RX_META_FIFO_WIDTH)) rx_data_fifo_read_mon();

taiga #(
	.TX_DATA_FIFO_SIZE(TX_DATA_FIFO_SIZE),
	.TX_DATA_FIFO_WIDTH(TX_DATA_FIFO_WIDTH),
	.RX_DATA_FIFO_SIZE(RX_DATA_FIFO_SIZE),
	.RX_DATA_FIFO_WIDTH(RX_DATA_FIFO_WIDTH),
	.USE_SP_UNIT_TX(USE_SP_UNIT_TX),
	.USE_SP_UNIT_RX(USE_SP_UNIT_RX)
) cpu(
	.clk(clock),
	.rst(cpu_reset),

	.instruction_bram,
	.data_bram,
	.acp_bram_a,
	.acp_bram_port_b_i(acp_bram_b),

	.l2(l2),
	.timer_interrupt,
	.interrupt,

	//.rx_data_fifo_write_mon,
	//.rx_data_fifo_read_mon,

	.io_axi_axcache,
	.m_axi_io,

	.m_axi_acp_aw,
	.m_axi_acp_w,
	.m_axi_acp_b,
	.m_axi_acp_ar,
	.m_axi_acp_r,

	.m_axi_dma_aw,
	.m_axi_dma_w,
	.m_axi_dma_b,
	.m_axi_dma_ar,
	.m_axi_dma_r,

	.gem_rx,
	.gem_tx,

	.mmr_rw,
	.mmr_r,
	.mmr_i
);

xpm_memory_tdpram #(
	.ADDR_WIDTH_A(IBRAM_ADDR_WIDTH),
	.ADDR_WIDTH_B(IBRAM_ADDR_WIDTH),
	.AUTO_SLEEP_TIME(0),
	.BYTE_WRITE_WIDTH_A(8),
	.BYTE_WRITE_WIDTH_B(8),
	.CASCADE_HEIGHT(0),
	.CLOCKING_MODE("common_clock"),
	.ECC_MODE("no_ecc"),
	.MEMORY_INIT_FILE("none"),
	.MEMORY_INIT_PARAM("0"),
	.MEMORY_OPTIMIZATION("true"),
	.MEMORY_PRIMITIVE("auto"),
	.MEMORY_SIZE(IBRAM_SIZE*8),
	.MESSAGE_CONTROL(0),
	.READ_DATA_WIDTH_A(IBRAM_DATA_WIDTH),
	.READ_DATA_WIDTH_B(IBRAM_DATA_WIDTH),
	.READ_LATENCY_A(1),
	.READ_LATENCY_B(1),
	.READ_RESET_VALUE_A("0"),
	.READ_RESET_VALUE_B("0"),
	.RST_MODE_A("SYNC"),
	.RST_MODE_B("SYNC"),
	.SIM_ASSERT_CHK(0),
	.USE_EMBEDDED_CONSTRAINT(0),
	.USE_MEM_INIT(1),
	.WAKEUP_TIME("disable_sleep"),
	.WRITE_DATA_WIDTH_A(IBRAM_DATA_WIDTH),
	.WRITE_DATA_WIDTH_B(IBRAM_DATA_WIDTH),
	.WRITE_MODE_A("no_change"),
	.WRITE_MODE_B("no_change")
)
xpm_memory_tdpram_ibram (
	.clka(clock),
	.rsta(~resetn),
	.rstb(~resetn),
	.douta(instruction_bram.data_out),
	.doutb(instruction_bram_mmr.data_out),
	.addra(instruction_bram.addr[IBRAM_ADDR_WIDTH-1:0]),
	.addrb(instruction_bram_mmr.addr[IBRAM_ADDR_WIDTH-1:0]),
	.dina(instruction_bram.data_in),
	.dinb(instruction_bram_mmr.data_in),
	.ena(instruction_bram.en),
	.enb(instruction_bram_mmr.en),
	.wea(instruction_bram.be),
	.web(instruction_bram_mmr.be)
);

xpm_memory_tdpram #(
	.ADDR_WIDTH_A(DBRAM_ADDR_WIDTH),
	.ADDR_WIDTH_B(DBRAM_ADDR_WIDTH),
	.AUTO_SLEEP_TIME(0),
	.BYTE_WRITE_WIDTH_A(8),
	.BYTE_WRITE_WIDTH_B(8),
	.CASCADE_HEIGHT(0),
	.CLOCKING_MODE("common_clock"),
	.ECC_MODE("no_ecc"),
	.MEMORY_INIT_FILE("none"),
	.MEMORY_INIT_PARAM("0"),
	.MEMORY_OPTIMIZATION("true"),
	.MEMORY_PRIMITIVE("auto"),
	.MEMORY_SIZE(DBRAM_SIZE*8),
	.MESSAGE_CONTROL(0),
	.READ_DATA_WIDTH_A(DBRAM_DATA_WIDTH),
	.READ_DATA_WIDTH_B(DBRAM_DATA_WIDTH),
	.READ_LATENCY_A(1),
	.READ_LATENCY_B(1),
	.READ_RESET_VALUE_A("0"),
	.READ_RESET_VALUE_B("0"),
	.RST_MODE_A("SYNC"),
	.RST_MODE_B("SYNC"),
	.SIM_ASSERT_CHK(0),
	.USE_EMBEDDED_CONSTRAINT(0),
	.USE_MEM_INIT(1),
	.WAKEUP_TIME("disable_sleep"),
	.WRITE_DATA_WIDTH_A(DBRAM_DATA_WIDTH),
	.WRITE_DATA_WIDTH_B(DBRAM_DATA_WIDTH),
	.WRITE_MODE_A("no_change"),
	.WRITE_MODE_B("no_change")
)
xpm_memory_tdpram_dbram (
	.clka(clock),
	.rsta(~resetn),
	.rstb(~resetn),
	.douta(data_bram.data_out),
	.doutb(data_bram_mmr.data_out),
	.addra(data_bram.addr[DBRAM_ADDR_WIDTH-1:0]),
	.addrb(data_bram_mmr.addr[DBRAM_ADDR_WIDTH-1:0]),
	.dina(data_bram.data_in),
	.dinb(data_bram_mmr.data_in),
	.ena(data_bram.en),
	.enb(data_bram_mmr.en),
	.wea(data_bram.be),
	.web(data_bram_mmr.be)
);

xpm_memory_tdpram #(
	.ADDR_WIDTH_A(ACPBRAM_A_ADDR_WIDTH),
	.ADDR_WIDTH_B(ACPBRAM_B_ADDR_WIDTH),
	.AUTO_SLEEP_TIME(0),
	.BYTE_WRITE_WIDTH_A(8),
	.BYTE_WRITE_WIDTH_B(8),
	.CASCADE_HEIGHT(0),
	.CLOCKING_MODE("common_clock"),
	.ECC_MODE("no_ecc"),
	.MEMORY_INIT_FILE("none"),
	.MEMORY_INIT_PARAM("0"),
	.MEMORY_OPTIMIZATION("true"),
	.MEMORY_PRIMITIVE("auto"),
	.MEMORY_SIZE(2*64*8),
	.MESSAGE_CONTROL(0),
	.READ_DATA_WIDTH_A(ACPBRAM_A_DATA_WIDTH),
	.READ_DATA_WIDTH_B(ACPBRAM_B_DATA_WIDTH),
	.READ_LATENCY_A(1),
	.READ_LATENCY_B(1),
	.READ_RESET_VALUE_A("0"),
	.READ_RESET_VALUE_B("0"),
	.RST_MODE_A("SYNC"),
	.RST_MODE_B("SYNC"),
	.SIM_ASSERT_CHK(0),
	.USE_EMBEDDED_CONSTRAINT(0),
	.USE_MEM_INIT(0),
	.WAKEUP_TIME("disable_sleep"),
	.WRITE_DATA_WIDTH_A(ACPBRAM_A_DATA_WIDTH),
	.WRITE_DATA_WIDTH_B(ACPBRAM_B_DATA_WIDTH),
	.WRITE_MODE_A("no_change"),
	.WRITE_MODE_B("no_change")
)
xpm_memory_tdpram_acpbram (
	.clka(clock),
	.rsta(~resetn),
	.rstb(~resetn),
	.douta(acp_bram_a.data_out),
	.doutb(acp_bram_b.dout),
	.addra(acp_bram_a.addr[ACPBRAM_A_ADDR_WIDTH-1:0]),
	.addrb(acp_bram_b.addr),
	.dina(acp_bram_a.data_in),
	.dinb(acp_bram_b.din),
	.ena(acp_bram_a.en),
	.enb(acp_bram_b.en),
	.wea(acp_bram_a.be),
	.web(acp_bram_b.we)
);

endmodule
