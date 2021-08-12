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
	parameter int C_M_AXI_DATA_WIDTH = 32
)
(
	input wire clock,
	input wire reset,

		// Instruction BRAM
	output wire [31:0] ibram_addrb,
	output wire ibram_clkb,
	output wire [31:0] ibram_dinb,
	input wire [31:0] ibram_doutb,
	output wire ibram_enb,
	output wire ibram_rstb,
	output wire [3:0] ibram_web,

	// Data BRAM
	output wire [31:0] dbram_addrb,
	output wire dbram_clkb,
	output wire [31:0] dbram_dinb,
	input wire [31:0] dbram_doutb,
	output wire dbram_enb,
	output wire dbram_rstb,
	output wire [3:0] dbram_web,

	// FIFO
	output wire [RX_META_FIFO_WRITE_WIDTH-1:0] rx_meta_fifo_write_wr_data,
	output wire rx_meta_fifo_write_wr_en,
	output wire rx_meta_fifo_write_full,
	output wire rx_meta_fifo_write_almost_full,

	// FIFO
	output wire [RX_META_FIFO_WRITE_WIDTH-1:0] rx_meta_fifo_read_rd_data,
	output wire rx_meta_fifo_read_rd_en,
	output wire rx_meta_fifo_read_empty,
	output wire rx_meta_fifo_read_almost_empty,

	output wire [31:0] instr_pc,
	output wire [31:0] instr_data,

	output wire e_issue_gc_unit_new_request,
	output wire [9:0] e_unit_needed,
	output wire [9:0] e_unit_needed_issue_stage,
	output wire e_unit_needed_gc_unit,
	output wire [4:0] e_opcode_trim,
	output wire e_issue_new_request,
	output wire e_second_cycle_flush,
	output wire e_processing_csr,
	output wire e_next_state_in,
	output wire e_potential_branch_exception,
	output wire e_issue_stage_valid,
	output wire e_gc_issue_hold,
	output wire e_gc_fetch_flush,
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

	input wire gem_tx_clock,
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
	input wire gem_rx_w_wr,
	input wire [31:0] gem_rx_w_data,
	input wire gem_rx_w_sop,
	input wire gem_rx_w_eop,
	input wire [44:0] gem_rx_w_status,
	input wire gem_rx_w_err,
	output wire gem_rx_w_overflow,
	input wire gem_rx_w_flush
);

	trace_outputs_t tr;

	assign instr_pc = tr.instruction_pc_dec;
	assign instr_data = tr.instruction_data_dec;

	assign e_issue_gc_unit_new_request = tr.events.issue_gc_unit_new_request;
	assign e_unit_needed = tr.events.unit_needed;
	assign e_unit_needed_issue_stage = tr.events.unit_needed_issue_stage;
	assign e_unit_needed_gc_unit = tr.events.unit_needed_gc_unit;
	assign e_opcode_trim = tr.events.opcode_trim;

	assign e_issue_new_request = tr.events.issue_new_request;
	assign e_second_cycle_flush = tr.events.second_cycle_flush;
	assign e_processing_csr = tr.events.processing_csr;
	assign e_next_state_in = tr.events.next_state_in;
	assign e_potential_branch_exception = tr.events.potential_branch_exception;
	assign e_issue_stage_valid = tr.events.issue_stage_valid;
	assign e_gc_issue_hold = tr.events.gc_issue_hold;
	assign e_gc_fetch_flush = tr.events.gc_fetch_flush;

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

	/*
	 * Local memory interfaces
	 */
	local_memory_interface instruction_bram();
	assign ibram_addrb = {instruction_bram.addr, 2'b00};
	assign ibram_clkb = clock;
	assign ibram_dinb = instruction_bram.data_in;
	assign instruction_bram.data_out = ibram_doutb;
	assign ibram_enb = instruction_bram.en;
	assign ibram_rstb = reset;
	assign ibram_web = instruction_bram.be;

	local_memory_interface data_bram();
	assign dbram_addrb = {data_bram.addr, 2'b00};
	assign dbram_clkb = clock;
	assign dbram_dinb = data_bram.data_in;
	assign data_bram.data_out = dbram_doutb;
	assign dbram_enb = data_bram.en;
	assign dbram_rstb = reset;
	assign dbram_web = data_bram.be;

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
	assign gem.rx_w_wr = gem_rx_w_wr;
	assign gem.rx_w_data = gem_rx_w_data;
	assign gem.rx_w_sop = gem_rx_w_sop;
	assign gem.rx_w_eop = gem_rx_w_eop;
	assign gem.rx_w_status = gem_rx_w_status;
	assign gem.rx_w_err = gem_rx_w_err;
	assign gem_rx_w_overflow = gem.rx_w_overflow;
	assign gem.rx_w_flush = gem_rx_w_flush;

    wire timer_interrupt;
    wire interrupt;

	fifo_write_interface #(.DATA_WIDTH(RX_META_FIFO_WRITE_WIDTH)) rx_meta_fifo_write_mon();
	assign rx_meta_fifo_write_wr_en = rx_meta_fifo_write_mon.wr_en;
	assign rx_meta_fifo_write_wr_data = rx_meta_fifo_write_mon.wr_data;
	assign rx_meta_fifo_write_almost_full = rx_meta_fifo_write_mon.almost_full;
	assign rx_meta_fifo_write_full = rx_meta_fifo_write_mon.full;
	fifo_read_interface #(.DATA_WIDTH(RX_META_FIFO_READ_WIDTH)) rx_meta_fifo_read_mon();
	assign rx_meta_fifo_read_rd_en = rx_meta_fifo_read_mon.rd_en;
	assign rx_meta_fifo_read_rd_data = rx_meta_fifo_read_mon.rd_data;
	assign rx_meta_fifo_read_almost_empty = rx_meta_fifo_read_mon.almost_empty;
	assign rx_meta_fifo_read_empty = rx_meta_fifo_read_mon.empty;

    avalon_interface m_avalon();
    wishbone_interface m_wishbone();
	l2_requester_interface l2();

    taiga cpu(
		.clk(clock),
		.rst(reset),
		.*
	);
endmodule
