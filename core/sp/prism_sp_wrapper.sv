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
import taiga_config::*;
import taiga_types::*;
import l2_config_and_types::*;

module prism_sp_wrapper #(
	parameter int RX_META_FIFO_READ_WIDTH = 32,
	parameter int RX_META_FIFO_WRITE_WIDTH = 32,
	parameter int C_M_AXI_ADDR_WIDTH = 32,
	parameter int C_M_AXI_DATA_WIDTH = 32,
	parameter int C_S_AXIL_ADDR_WIDTH = 32,
	parameter int C_S_AXIL_DATA_WIDTH = 32
)
(
	input wire clock,
	input wire resetn,

	output wire gem_irq,

`ifdef IBRAM_MON
	// Instruction BRAM
	output wire [31:0] ibram_addrb,
	output wire ibram_clkb,
	output wire [31:0] ibram_dinb,
	output wire [31:0] ibram_doutb,
	output wire ibram_enb,
	output wire ibram_rstb,
	output wire [3:0] ibram_web,
`endif

`ifdef DBRAM_MON
	// Data BRAM
	output wire [31:0] dbram_addrb,
	output wire dbram_clkb,
	output wire [31:0] dbram_dinb,
	output wire [31:0] dbram_doutb,
	output wire dbram_enb,
	output wire dbram_rstb,
	output wire [3:0] dbram_web,
`endif

`ifdef RX_DATA_FIFO_MON
	// FIFO
	output wire [RX_META_FIFO_WRITE_WIDTH-1:0] rx_data_fifo_write_wr_data,
	output wire rx_data_fifo_write_wr_en,
	output wire rx_data_fifo_write_full,
	output wire rx_data_fifo_write_almost_full,

	// FIFO
	output wire [RX_META_FIFO_WRITE_WIDTH-1:0] rx_data_fifo_read_rd_data,
	output wire rx_data_fifo_read_rd_en,
	output wire rx_data_fifo_read_empty,
	output wire rx_data_fifo_read_almost_empty,
`endif

`ifdef TRACE_SIGNALS
	output wire e_operand_stall,
	output wire e_unit_stall,
	output wire e_no_id_stall,
	output wire e_no_instruction_stall,
	output wire e_other_stall,
	output wire e_instruction_issued_dec,
	output wire e_branch_operand_stall,
	output wire e_alu_operand_stall,
	output wire e_ls_operand_stall,
	output wire e_div_operand_stall,
	output wire e_alu_op,
	output wire e_branch_or_jump_op,
	output wire e_load_op,
	output wire e_store_op,
	output wire e_mul_op,
	output wire e_div_op,
	output wire e_misc_op,
	output wire e_branch_correct,
	output wire e_branch_misspredict,
	output wire e_return_correct,
	output wire e_return_misspredict,
`endif

	// AXI-lite slave interface
	input wire s_axil_awvalid,
	output wire s_axil_awready,
	input wire [C_S_AXIL_ADDR_WIDTH-1:0] s_axil_awaddr,
	input wire [2:0] s_axil_awprot,

	input wire s_axil_wvalid,
	output wire s_axil_wready,
	input wire [C_S_AXIL_DATA_WIDTH-1:0] s_axil_wdata,
	input wire [(C_S_AXIL_DATA_WIDTH/8)-1:0] s_axil_wstrb,

	output wire s_axil_bvalid,
	input wire s_axil_bready,
	output wire [1:0] s_axil_bresp,

	input wire s_axil_arvalid,
	output wire s_axil_arready,
	input wire [C_S_AXIL_ADDR_WIDTH-1:0] s_axil_araddr,
	input wire [2:0] s_axil_arprot,

	output wire s_axil_rvalid,
	input wire s_axil_rready,
	output wire [C_S_AXIL_DATA_WIDTH-1:0] s_axil_rdata,
	output wire [1:0] s_axil_rresp,

	// IO access
	output wire m_axi_io_arvalid,
	input wire m_axi_io_arready,
	output wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_io_araddr,
	output wire [7:0] m_axi_io_arlen,
	output wire [2:0] m_axi_io_arsize,
	output wire [1:0] m_axi_io_arburst,
	output wire [3:0] m_axi_io_arcache,
	output wire [5:0] m_axi_io_arid,
	input wire m_axi_io_rvalid,
	output wire m_axi_io_rready,
	input wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_io_rdata,
	input wire [1:0] m_axi_io_rresp,
	input wire m_axi_io_rlast,
	input wire [5:0] m_axi_io_rid,
	output wire m_axi_io_awvalid,
	input wire m_axi_io_awready,
	output wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_io_awaddr,
	output wire [7:0] m_axi_io_awlen,
	output wire [2:0] m_axi_io_awsize,
	output wire [1:0] m_axi_io_awburst,
	output wire [3:0] m_axi_io_awcache,
	output wire [5:0] m_axi_io_awid,
	output wire m_axi_io_wvalid,
	input wire m_axi_io_wready,
	output wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_io_wdata,
	output wire [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_io_wstrb,
	output wire m_axi_io_wlast,
	input wire m_axi_io_bvalid,
	output wire m_axi_io_bready,
	input wire [1:0] m_axi_io_bresp,
	input wire [5:0] m_axi_io_bid,

	// GEM DMA
	input wire m_axi_dma_arready,
	output wire m_axi_dma_arvalid,
	output wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_dma_araddr,
	output wire [7:0] m_axi_dma_arlen,
	output wire [2:0] m_axi_dma_arsize,
	output wire [1:0] m_axi_dma_arburst,
	output wire [3:0] m_axi_dma_arcache,
	output wire [5:0] m_axi_dma_arid,
	output wire m_axi_dma_rready,
	input wire m_axi_dma_rvalid,
	input wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_dma_rdata,
	input wire [1:0] m_axi_dma_rresp,
	input wire m_axi_dma_rlast,
	input wire [5:0] m_axi_dma_rid,
	input wire m_axi_dma_awready,
	output wire m_axi_dma_awvalid,
	output wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_dma_awaddr,
	output wire [7:0] m_axi_dma_awlen,
	output wire [2:0] m_axi_dma_awsize,
	output wire [1:0] m_axi_dma_awburst,
	output wire [3:0] m_axi_dma_awcache,
	output wire [5:0] m_axi_dma_awid,
	input wire m_axi_dma_wready,
	output wire m_axi_dma_wvalid,
	output wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_dma_wdata,
	output wire [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_dma_wstrb,
	output wire m_axi_dma_wlast,
	input wire m_axi_dma_bvalid,
	output wire m_axi_dma_bready,
	input wire [1:0] m_axi_dma_bresp,
	input wire [5:0] m_axi_dma_bid,

	// GEM Interface
	input wire gem_tx_clock,
	input wire gem_tx_resetn,
	output wire gem_tx_r_data_rdy,
	input wire gem_tx_r_rd,
	output wire gem_tx_r_valid,
	output wire [7:0] gem_tx_r_data,
	output wire gem_tx_r_sop,
	output wire gem_tx_r_eop,
	output wire gem_tx_r_err,
	output wire gem_tx_r_underflow,
	output wire gem_tx_r_flushed,
	output wire gem_tx_r_control,
	input wire [3:0] gem_tx_r_status,
	input wire gem_tx_r_fixed_lat,

	input wire gem_dma_tx_end_tog,
	output wire gem_dma_tx_status_tog,

	input wire gem_rx_clock,
	input wire gem_rx_resetn,
	input wire gem_rx_w_wr,
	input wire [31:0] gem_rx_w_data,
	input wire gem_rx_w_sop,
	input wire gem_rx_w_eop,
	input wire [44:0] gem_rx_w_status,
	input wire gem_rx_w_err,
	output wire gem_rx_w_overflow,
	input wire gem_rx_w_flush
);

`ifdef TRACE_SIGNALS
trace_outputs_t tr;
assign e_operand_stall = tr.events.operand_stall;
assign e_unit_stall = tr.events.unit_stall;
assign e_no_id_stall = tr.events.no_id_stall;
assign e_no_instruction_stall = tr.events.no_instruction_stall;
assign e_other_stall = tr.events.other_stall;
assign e_instruction_issued_dec = tr.events.instruction_issued_dec;
assign e_branch_operand_stall = tr.events.branch_operand_stall;
assign e_alu_operand_stall = tr.events.alu_operand_stall;
assign e_ls_operand_stall = tr.events.ls_operand_stall;
assign e_div_operand_stall = tr.events.div_operand_stall;
assign e_alu_op = tr.events.alu_op;
assign e_branch_or_jump_op = tr.events.branch_or_jump_op;
assign e_load_op = tr.events.load_op;
assign e_store_op = tr.events.store_op;
assign e_mul_op = tr.events.mul_op;
assign e_div_op = tr.events.div_op;
assign e_misc_op = tr.events.misc_op;
assign e_branch_correct = tr.events.branch_correct;
assign e_branch_misspredict = tr.events.branch_misspredict;
assign e_return_correct = tr.events.return_correct;
assign e_return_misspredict = tr.events.return_misspredict;
`endif

/*
 * Local memory interfaces
 */
local_memory_interface instruction_bram();
local_memory_interface instruction_bram_mmr();
`ifdef IBRAM_MON
assign ibram_addrb = instruction_bram_mmr.addr;
assign ibram_dinb = instruction_bram_mmr.data_in;
assign ibram_doutb = instruction_bram_mmr.data_out;
assign ibram_enb = instruction_bram_mmr.en;
assign ibram_web = instruction_bram_mmr.be;
`endif

local_memory_interface data_bram();
local_memory_interface data_bram_mmr();
`ifdef DBRAM_MON
assign dbram_addrb = data_bram_mmr.addr;
assign dbram_dinb = data_bram_mmr.data_in;
assign dbram_doutb = data_bram_mmr.data_out;
assign dbram_enb = data_bram_mmr.en;
assign dbram_web = data_bram_mmr.be;
`endif

/*
 * AXI IO
 */
axi_interface m_axi_io();
// AR
// assign m_axi_arid = m_axi.arid;
assign m_axi_io_arvalid = m_axi_io.arvalid;
assign m_axi_io_araddr = m_axi_io.araddr;
assign m_axi_io_arlen = m_axi_io.arlen;
assign m_axi_io_arsize = m_axi_io.arsize;
assign m_axi_io_arburst = m_axi_io.arburst;
assign m_axi_io_arcache = m_axi_io.arcache;
assign m_axi_io.arready = m_axi_io_arready;
// R
// assign m_axi_io_rid = m_axi.rid;
assign m_axi_io.rvalid = m_axi_io_rvalid;
assign m_axi_io.rdata = m_axi_io_rdata;
assign m_axi_io.rresp = m_axi_io_rresp;
assign m_axi_io.rlast = m_axi_io_rlast;
assign m_axi_io_rready = m_axi_io.rready;
// AW
assign m_axi_io_awvalid = m_axi_io.awvalid;
assign m_axi_io_awaddr = m_axi_io.awaddr;
assign m_axi_io_awlen = m_axi_io.awlen;
assign m_axi_io_awsize = m_axi_io.awsize;
assign m_axi_io_awburst = m_axi_io.awburst;
assign m_axi_io_awcache = m_axi_io.awcache;
assign m_axi_io.awready = m_axi_io_awready;
// W
assign m_axi_io_wvalid = m_axi_io.wvalid;
assign m_axi_io_wdata = m_axi_io.wdata;
assign m_axi_io_wstrb = m_axi_io.wstrb;
assign m_axi_io_wlast = m_axi_io.wlast;
assign m_axi_io.wready = m_axi_io_wready;
// B
// assign m_axi_io_bid = m_axi.bid;
assign m_axi_io.bvalid = m_axi_io_bvalid;
assign m_axi_io.bresp = m_axi_io_bresp;
assign m_axi_io_bready = m_axi_io.bready;

/*
 * AXI DMA
 */
axi_write_address_channel m_axi_dma_aw();
axi_write_channel m_axi_dma_w();
axi_write_response_channel m_axi_dma_b();
axi_read_address_channel m_axi_dma_ar();
axi_read_channel m_axi_dma_r();
// AR
// assign m_axi_arid = m_axi.arid;
assign m_axi_dma_arvalid = m_axi_dma_ar.arvalid;
assign m_axi_dma_araddr = m_axi_dma_ar.araddr;
assign m_axi_dma_arlen = m_axi_dma_ar.arlen;
assign m_axi_dma_arsize = m_axi_dma_ar.arsize;
assign m_axi_dma_arburst = m_axi_dma_ar.arburst;
assign m_axi_dma_arcache = m_axi_dma_ar.arcache;
assign m_axi_dma_ar.arready = m_axi_dma_arready;
// R
// assign m_axi_dma_rid = m_axi.rid;
assign m_axi_dma_r.rvalid = m_axi_dma_rvalid;
assign m_axi_dma_r.rdata = m_axi_dma_rdata;
assign m_axi_dma_r.rresp = m_axi_dma_rresp;
assign m_axi_dma_r.rlast = m_axi_dma_rlast;
assign m_axi_dma_rready = m_axi_dma_r.rready;
// AW
assign m_axi_dma_awvalid = m_axi_dma_aw.awvalid;
assign m_axi_dma_awaddr = m_axi_dma_aw.awaddr;
assign m_axi_dma_awlen = m_axi_dma_aw.awlen;
assign m_axi_dma_awsize = m_axi_dma_aw.awsize;
assign m_axi_dma_awburst = m_axi_dma_aw.awburst;
assign m_axi_dma_awcache = m_axi_dma_aw.awcache;
assign m_axi_dma_aw.awready = m_axi_dma_awready;
// W
assign m_axi_dma_wvalid = m_axi_dma_w.wvalid;
assign m_axi_dma_wdata = m_axi_dma_w.wdata;
assign m_axi_dma_wstrb = m_axi_dma_w.wstrb;
assign m_axi_dma_wlast = m_axi_dma_w.wlast;
assign m_axi_dma_w.wready = m_axi_dma_wready;
// B
// assign m_axi_dma_bid = m_axi.bid;
assign m_axi_dma_b.bvalid = m_axi_dma_bvalid;
assign m_axi_dma_b.bresp = m_axi_dma_bresp;
assign m_axi_dma_bready = m_axi_dma_b.bready;

/*
 * GEM
 */
gem_interface gem();
assign gem.tx_clock = gem_tx_clock;
assign gem.tx_resetn = gem_tx_resetn;
assign gem_tx_r_data_rdy = gem.tx_r_data_rdy;
assign gem.tx_r_rd = gem_tx_r_rd;
assign gem_tx_r_valid = gem.tx_r_valid;
assign gem_tx_r_data = gem.tx_r_data;
assign gem_tx_r_sop = gem.tx_r_sop;
assign gem_tx_r_eop = gem.tx_r_eop;
assign gem_tx_r_err = gem.tx_r_err;
assign gem_tx_r_underflow = gem.tx_r_underflow;
assign gem_tx_r_flushed = gem.tx_r_flushed;
assign gem_tx_r_control = gem.tx_r_control;
assign gem.tx_r_status = gem_tx_r_status;
assign gem.tx_r_fixed_lat = gem_tx_r_fixed_lat;
assign gem.dma_tx_end_tog = gem_dma_tx_end_tog;
assign gem_dma_tx_status_tog = gem.dma_tx_status_tog;
assign gem.rx_clock = gem_rx_clock;
assign gem.rx_resetn = gem_rx_resetn;
assign gem.rx_w_wr = gem_rx_w_wr;
assign gem.rx_w_data = gem_rx_w_data;
assign gem.rx_w_sop = gem_rx_w_sop;
assign gem.rx_w_eop = gem_rx_w_eop;
assign gem.rx_w_status = gem_rx_w_status;
assign gem.rx_w_err = gem_rx_w_err;
assign gem_rx_w_overflow = gem.rx_w_overflow;
assign gem.rx_w_flush = gem_rx_w_flush;

fifo_write_interface #(.DATA_WIDTH(RX_META_FIFO_WRITE_WIDTH)) rx_data_fifo_write_mon();
assign rx_data_fifo_write_wr_en = rx_data_fifo_write_mon.wr_en;
assign rx_data_fifo_write_wr_data = rx_data_fifo_write_mon.wr_data;
assign rx_data_fifo_write_almost_full = rx_data_fifo_write_mon.almost_full;
assign rx_data_fifo_write_full = rx_data_fifo_write_mon.full;
fifo_read_interface #(.DATA_WIDTH(RX_META_FIFO_READ_WIDTH)) rx_data_fifo_read_mon();
assign rx_data_fifo_read_rd_en = rx_data_fifo_read_mon.rd_en;
assign rx_data_fifo_read_rd_data = rx_data_fifo_read_mon.rd_data;
assign rx_data_fifo_read_almost_empty = rx_data_fifo_read_mon.almost_empty;
assign rx_data_fifo_read_empty = rx_data_fifo_read_mon.empty;

// These signals are inputs to the Taiga core and are
// needed for now.
wire logic timer_interrupt;
wire logic interrupt;
avalon_interface m_avalon();
wishbone_interface m_wishbone();
l2_requester_interface l2();

axi_lite_write_address_channel #(.AXI_AWADDR_WIDTH(C_S_AXIL_ADDR_WIDTH)) s_axil_aw();
assign s_axil_aw.awvalid = s_axil_awvalid;
assign s_axil_awready = s_axil_aw.awready;
assign s_axil_aw.awaddr = s_axil_awaddr;
assign s_axil_aw.awprot = s_axil_awprot;
axi_lite_write_channel #(.AXI_WDATA_WIDTH(C_S_AXIL_DATA_WIDTH)) s_axil_w();
assign s_axil_w.wvalid = s_axil_wvalid;
assign s_axil_wready = s_axil_w.wready;
assign s_axil_w.wdata = s_axil_wdata;
assign s_axil_w.wstrb = s_axil_wstrb;
axi_lite_write_response_channel s_axil_b();
assign s_axil_bvalid = s_axil_b.bvalid;
assign s_axil_b.bready = s_axil_bready;
assign s_axil_bresp = s_axil_b.bresp;
axi_lite_read_address_channel #(.AXI_ARADDR_WIDTH(C_S_AXIL_ADDR_WIDTH)) s_axil_ar();
assign s_axil_ar.arvalid = s_axil_arvalid;
assign s_axil_arready = s_axil_ar.arready;
assign s_axil_ar.araddr = s_axil_araddr;
assign s_axil_ar.arprot = s_axil_arprot;
axi_lite_read_channel #(.AXI_RDATA_WIDTH(C_S_AXIL_DATA_WIDTH)) s_axil_r();
assign s_axil_rvalid = s_axil_r.rvalid;
assign s_axil_r.rready = s_axil_rready;
assign s_axil_rdata = s_axil_r.rdata;
assign s_axil_rresp = s_axil_r.rresp;

mmr_readwrite_interface #(.NREGS(MMR_RW_NREGS)) mmr_rw();
mmr_read_interface #(.NREGS(MMR_R_NREGS)) mmr_r();
mmr_intr_interface #(.N(NGEMQUEUES),.WIDTH(32)) mmr_i();

assign gem_irq = |mmr_i.interrupts;

localparam int IBRAM_SIZE = 32 * 1024;
localparam int IBRAM_WIDTH = 32;
localparam int DBRAM_SIZE = 32 * 1024;
localparam int DBRAM_WIDTH = 32;

wire logic cpu_reset;

axi_lite_mmr #(
	.IBRAM_SIZE(IBRAM_SIZE),
	.DBRAM_SIZE(DBRAM_SIZE)
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

	.instruction_bram_mmr(instruction_bram_mmr),
	.data_bram_mmr(data_bram_mmr)
);

taiga cpu(
	.clk(clock),
	.rst(cpu_reset),
	.mmr_rw(mmr_rw),
	.mmr_r(mmr_r),
	.mmr_i(mmr_i),
	.*
);

localparam int IBRAM_ADDR_WIDTH = $clog2(IBRAM_SIZE / (IBRAM_WIDTH/8));

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
	.READ_DATA_WIDTH_A(IBRAM_WIDTH),
	.READ_DATA_WIDTH_B(IBRAM_WIDTH),
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
	.WRITE_DATA_WIDTH_A(IBRAM_WIDTH),
	.WRITE_DATA_WIDTH_B(IBRAM_WIDTH),
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

localparam int DBRAM_ADDR_WIDTH = $clog2(DBRAM_SIZE / (DBRAM_WIDTH/8));

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
	.READ_DATA_WIDTH_A(DBRAM_WIDTH),
	.READ_DATA_WIDTH_B(DBRAM_WIDTH),
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
	.WRITE_DATA_WIDTH_A(DBRAM_WIDTH),
	.WRITE_DATA_WIDTH_B(DBRAM_WIDTH),
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

endmodule
