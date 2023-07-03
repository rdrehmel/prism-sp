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
import sp_unit_config::*;
module sp_unit_rx#(
	parameter int RX_DATA_FIFO_SIZE,
	parameter int RX_DATA_FIFO_WIDTH,
	parameter int RESULT_WIDTH
)
(
	input wire logic clk,
	input wire logic rst,

	input sp_inputs_t sp_inputs,
	unit_issue_interface.unit issue,
	unit_writeback_interface.unit wb,

	input wire logic [SP_UNIT_RX_NCMDS-1:0] issue_cmd,
	output wire logic [SP_UNIT_RX_NCMDS-1:0] cmds_busy,
	output wire logic [SP_UNIT_RX_NCMDS-1:0] cmds_done,
	output var logic [RESULT_WIDTH-1:0] result,

	axi_write_address_channel.master m_axi_dma_aw,
	axi_write_channel.master m_axi_dma_w,
	axi_write_response_channel.master m_axi_dma_b,

	gem_rx_interface.slave gem_rx
);

// This is currently redundant.
// But we might need it later in a transitional phase when both constants
// are made independent of each other.
if (m_axi_dma_w.AXI_WDATA_WIDTH != RX_DATA_FIFO_WIDTH) begin
	$error("We don't support m_axi_dma_w.AXI_WDATA_WIDTH != RX_DATA_FIFO_WIDTH)");
end

localparam int RX_META_FIFO_WIDTH = 32;
localparam int RX_META_FIFO_DEPTH = 2048;
localparam int RX_DATA_FIFO_DEPTH = RX_DATA_FIFO_SIZE / (RX_DATA_FIFO_WIDTH/8);

localparam int RX_META_FIFO_RD_DATA_COUNT_WIDTH = $clog2(RX_META_FIFO_DEPTH) + 1;
localparam int RX_META_FIFO_WR_DATA_COUNT_WIDTH = $clog2(RX_META_FIFO_DEPTH) + 1;
localparam int RX_DATA_FIFO_RD_DATA_COUNT_WIDTH = $clog2(RX_DATA_FIFO_DEPTH) + 1;
localparam int RX_DATA_FIFO_WR_DATA_COUNT_WIDTH = $clog2(RX_DATA_FIFO_DEPTH) + 1;

var logic [SP_UNIT_RX_NCMDS-1:0] cmds_busy_ff;
var logic [SP_UNIT_RX_NCMDS-1:0] cmds_busy_comb;
var logic [SP_UNIT_RX_NCMDS-1:0] cmds_done_ff;
var logic [SP_UNIT_RX_NCMDS-1:0] cmds_done_comb;
assign cmds_busy = cmds_busy_ff;
assign cmds_done = cmds_done_ff;

/*
 * Interfaces for the RX meta FIFO
 */
fifo_read_interface #(
	.DATA_WIDTH(RX_META_FIFO_WIDTH)
) rx_meta_fifo_r();
wire logic [RX_META_FIFO_RD_DATA_COUNT_WIDTH-1:0] rx_meta_fifo_r_rd_data_count;

fifo_write_interface #(
	.DATA_WIDTH(RX_META_FIFO_WIDTH)
) rx_meta_fifo_w();
wire logic [RX_META_FIFO_WR_DATA_COUNT_WIDTH-1:0] rx_meta_fifo_w_wr_data_count;

/*
 * Interfaces for the RX data FIFO
 */
fifo_read_interface #(
	.DATA_WIDTH(RX_DATA_FIFO_WIDTH)
) rx_data_fifo_r();
wire logic [RX_DATA_FIFO_RD_DATA_COUNT_WIDTH-1:0] rx_data_fifo_r_rd_data_count;

fifo_write_interface #(
	.DATA_WIDTH(RX_DATA_FIFO_WIDTH)
) rx_data_fifo_w();
wire logic [RX_DATA_FIFO_WR_DATA_COUNT_WIDTH-1:0] rx_data_fifo_w_wr_data_count;

memory_write_interface #(
	.DATA_WIDTH(RX_DATA_FIFO_WIDTH),
	.ADDR_WIDTH(32)
) rx_data_mem_w();

/*
 * --------  --------  --------  --------
 * PL Clock Domain
 * --------  --------  --------  --------
 */
/*
 * Command "RX META POP"
 */
var logic [31:0] rx_meta_fifo_read_rd_data;

always_comb begin
	cmds_done_comb[CMD_RX_META_POP] = cmds_done_ff[CMD_RX_META_POP];
	cmds_busy_comb[CMD_RX_META_POP] = cmds_busy_ff[CMD_RX_META_POP];

	if (rst) begin
		cmds_done_comb[CMD_RX_META_POP] = 1'b0;
		cmds_busy_comb[CMD_RX_META_POP] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_META_POP]) begin
			cmds_done_comb[CMD_RX_META_POP] = 1'b1;
			cmds_busy_comb[CMD_RX_META_POP] = 1'b1;
		end
		if (cmds_done_ff[CMD_RX_META_POP] & wb.ack) begin
			cmds_done_comb[CMD_RX_META_POP] = 1'b0;
			cmds_busy_comb[CMD_RX_META_POP] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_RX_META_POP] <= cmds_done_comb[CMD_RX_META_POP];
	cmds_busy_ff[CMD_RX_META_POP] <= cmds_busy_comb[CMD_RX_META_POP];

	if (rst) begin
		rx_meta_fifo_r.rd_en <= 1'b0;
	end
	else begin
		rx_meta_fifo_r.rd_en <= 1'b0;

		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_META_POP]) begin
			rx_meta_fifo_r.rd_en <= 1'b1;
			rx_meta_fifo_read_rd_data <= rx_meta_fifo_r.rd_data;
		end
	end
end

/*
 * "RX META EMPTY" command
 */
always_comb begin
	cmds_done_comb[CMD_RX_META_EMPTY] = cmds_done_ff[CMD_RX_META_EMPTY];
	cmds_busy_comb[CMD_RX_META_EMPTY] = cmds_busy_ff[CMD_RX_META_EMPTY];

	if (rst) begin
		cmds_done_comb[CMD_RX_META_EMPTY] = 1'b0;
		cmds_busy_comb[CMD_RX_META_EMPTY] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_META_EMPTY]) begin
			cmds_done_comb[CMD_RX_META_EMPTY] = 1'b1;
			cmds_busy_comb[CMD_RX_META_EMPTY] = 1'b1;
		end
		if (cmds_done_ff[CMD_RX_META_EMPTY] & wb.ack) begin
			cmds_done_comb[CMD_RX_META_EMPTY] = 1'b0;
			cmds_busy_comb[CMD_RX_META_EMPTY] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_RX_META_EMPTY] <= cmds_done_comb[CMD_RX_META_EMPTY];
	cmds_busy_ff[CMD_RX_META_EMPTY] <= cmds_busy_comb[CMD_RX_META_EMPTY];
end

/*
 * Command "RX DATA SKIP"
 */
always_comb begin
	cmds_done_comb[CMD_RX_DATA_SKIP] = cmds_done_ff[CMD_RX_DATA_SKIP];
	cmds_busy_comb[CMD_RX_DATA_SKIP] = cmds_busy_ff[CMD_RX_DATA_SKIP];

	if (rst) begin
		cmds_done_comb[CMD_RX_DATA_SKIP] = 1'b0;
		cmds_busy_comb[CMD_RX_DATA_SKIP] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_DATA_SKIP]) begin
			cmds_done_comb[CMD_RX_DATA_SKIP] = 1'b1;
			cmds_busy_comb[CMD_RX_DATA_SKIP] = 1'b1;
		end
		if (cmds_done_ff[CMD_RX_DATA_SKIP] & wb.ack) begin
			cmds_done_comb[CMD_RX_DATA_SKIP] = 1'b0;
			cmds_busy_comb[CMD_RX_DATA_SKIP] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_RX_DATA_SKIP] <= cmds_done_comb[CMD_RX_DATA_SKIP];
	cmds_busy_ff[CMD_RX_DATA_SKIP] <= cmds_busy_comb[CMD_RX_DATA_SKIP];
	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_DATA_SKIP]) begin
			// XXX Not implemented yet.
		end
	end
end

/*
 * Command "RX DATA DMA START"
 */
always_comb begin
	cmds_done_comb[CMD_RX_DATA_DMA_START] = cmds_done_ff[CMD_RX_DATA_DMA_START];
	cmds_busy_comb[CMD_RX_DATA_DMA_START] = cmds_busy_ff[CMD_RX_DATA_DMA_START];

	if (rst) begin
		cmds_done_comb[CMD_RX_DATA_DMA_START] = 1'b0;
		cmds_busy_comb[CMD_RX_DATA_DMA_START] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_DATA_DMA_START]) begin
			cmds_done_comb[CMD_RX_DATA_DMA_START] = 1'b1;
			cmds_busy_comb[CMD_RX_DATA_DMA_START] = 1'b1;
		end
		if (cmds_done_ff[CMD_RX_DATA_DMA_START] & wb.ack) begin
			cmds_done_comb[CMD_RX_DATA_DMA_START] = 1'b0;
			cmds_busy_comb[CMD_RX_DATA_DMA_START] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_RX_DATA_DMA_START] <= cmds_done_comb[CMD_RX_DATA_DMA_START];
	cmds_busy_ff[CMD_RX_DATA_DMA_START] <= cmds_busy_comb[CMD_RX_DATA_DMA_START];

	if (rst) begin
	end
	else begin
		rx_data_mem_w.start <= 1'b0;

		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_DATA_DMA_START]) begin
			rx_data_mem_w.start <= 1'b1;
			rx_data_mem_w.addr <= sp_inputs.rs1;
			rx_data_mem_w.len <= sp_inputs.rs2[15:0];
		end
	end
end

/*
 * Command "RX DATA DMA STATUS"
 */
var logic rx_data_dma_status_result_ff;

always_comb begin
	cmds_done_comb[CMD_RX_DATA_DMA_STATUS] = cmds_done_ff[CMD_RX_DATA_DMA_STATUS];
	cmds_busy_comb[CMD_RX_DATA_DMA_STATUS] = cmds_busy_ff[CMD_RX_DATA_DMA_STATUS];

	if (rst) begin
		cmds_done_comb[CMD_RX_DATA_DMA_STATUS] = 1'b0;
		cmds_busy_comb[CMD_RX_DATA_DMA_STATUS] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_DATA_DMA_STATUS]) begin
			cmds_done_comb[CMD_RX_DATA_DMA_STATUS] = 1'b1;
			cmds_busy_comb[CMD_RX_DATA_DMA_STATUS] = 1'b1;
		end
		if (cmds_done_ff[CMD_RX_DATA_DMA_STATUS] & wb.ack) begin
			cmds_done_comb[CMD_RX_DATA_DMA_STATUS] = 1'b0;
			cmds_busy_comb[CMD_RX_DATA_DMA_STATUS] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_RX_DATA_DMA_STATUS] <= cmds_done_comb[CMD_RX_DATA_DMA_STATUS];
	cmds_busy_ff[CMD_RX_DATA_DMA_STATUS] <= cmds_busy_comb[CMD_RX_DATA_DMA_STATUS];

	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_DATA_DMA_STATUS]) begin
			rx_data_dma_status_result_ff <= rx_data_mem_w.busy;
		end
	end
end

var logic [SP_UNIT_RX_NCMDS-1:0] cur_cmd;

always_ff @(posedge clk) begin
	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready) begin
			cur_cmd <= issue_cmd;
		end
	end
end

always_comb begin
	result = '0;

	// "Reverse case" statement for one-hot encoding.
	case (1'b1)
	//cur_cmd[CMD_RX_META_NELEMS]: result = 32'(rx_meta_nelems_comb);
	cur_cmd[CMD_RX_META_POP]: result = rx_meta_fifo_read_rd_data;
	cur_cmd[CMD_RX_META_EMPTY]: result[0] = rx_meta_fifo_r.empty;
	cur_cmd[CMD_RX_DATA_DMA_STATUS]: result[0] = rx_data_dma_status_result_ff;
	endcase
end

/*
 * --------  --------  --------  --------
 * GEM RX Interface Clock Domain
 * --------  --------  --------  --------
 */
localparam int MAX_PACKET_LENGTH = 2047;
//localparam RX_PACKET_BYTE_COUNT_WIDTH = $clog2(MAX_PACKET_LENGTH + 1);
localparam int RX_PACKET_BYTE_COUNT_WIDTH = 13;
var logic [RX_PACKET_BYTE_COUNT_WIDTH-1:0] rx_packet_byte_count_ff;
var logic [RX_PACKET_BYTE_COUNT_WIDTH-1:0] rx_packet_byte_count_comb;

always_comb begin
	rx_packet_byte_count_comb = rx_packet_byte_count_ff;

	if (!gem_rx.rx_resetn) begin
		rx_packet_byte_count_comb = '0;
	end
	else begin
		if (gem_rx.rx_w_sop) begin
			rx_packet_byte_count_comb = '0;
		end
		if (gem_rx.rx_w_wr) begin
			rx_packet_byte_count_comb = rx_packet_byte_count_comb + 1;
		end
	end
end

var logic [31:0] gem_rx_w_status_encoded;

gem_rx_w_status_encoder gem_rx_w_status_encoder_inst(
	.rx_w_status(gem_rx.rx_w_status),
	.frame_length(rx_packet_byte_count_comb),
	.out(gem_rx_w_status_encoded)
);

var logic rx_data_fifo_has_space_ff;
var logic rx_data_fifo_state;
// In number of bytes
var logic [$clog2(RX_DATA_FIFO_SIZE):0] rx_data_fifo_nfree;
var logic [13:0] gem_rx_w_status_13_0;

// This state machine checks whether there is enough space in the FIFO at
//  the start of frame (SOP).
always_ff @(posedge gem_rx.rx_clock) begin
	if (!gem_rx.rx_resetn) begin
		rx_data_fifo_state <= '0;
	end
	else begin
		case (rx_data_fifo_state)
		1'b0: begin
			if (gem_rx.rx_w_sop) begin
				gem_rx_w_status_13_0 <= gem_rx.rx_w_status[13:0];
				rx_data_fifo_nfree <= RX_DATA_FIFO_SIZE - { rx_data_fifo_w_wr_data_count, {($clog2(RX_DATA_FIFO_WIDTH/8)){1'b0}} };
				rx_data_fifo_state <= 1'b1;
			end
		end
		1'b1: begin
			rx_data_fifo_has_space_ff <= rx_data_fifo_nfree >= gem_rx_w_status_13_0;
			rx_data_fifo_state <= 1'b0;
		end
		endcase
	end
end

var logic [RX_DATA_FIFO_WIDTH-1:0] rx_cur_buf_comb;
var logic [RX_DATA_FIFO_WIDTH-1:0] rx_cur_buf_ff;
// A bit that is set represents a byte that is not valid.
var logic [(RX_DATA_FIFO_WIDTH/8)-1:0] rx_cur_buf_idx;

always_comb begin
	rx_cur_buf_comb = rx_cur_buf_ff;

	if (!gem_rx.rx_resetn) begin
	end
	else begin
		if (gem_rx.rx_w_sop) begin
			rx_cur_buf_comb = '0;
		end
		if (gem_rx.rx_w_wr) begin
			// Reset the buffer for data security/privacy reasons
			if (rx_cur_buf_idx[0]) begin
				rx_cur_buf_comb[RX_DATA_FIFO_WIDTH-1:8] = '0;
			end
			// Put the current data into the correct slot.
			for (int i = 0; i < RX_DATA_FIFO_WIDTH/8; i++) begin
				if (rx_cur_buf_idx[i]) begin
					rx_cur_buf_comb[i*8 +:8] = gem_rx.rx_w_data[7:0];
				end
			end
		end
	end
end

assign rx_data_fifo_w.wr_data = rx_cur_buf_ff;

always_ff @(posedge gem_rx.rx_clock) begin
	rx_cur_buf_ff <= rx_cur_buf_comb;
	rx_packet_byte_count_ff <= rx_packet_byte_count_comb;

	// Unpulse
	rx_meta_fifo_w.wr_en <= 1'b0;
	rx_data_fifo_w.wr_en <= 1'b0;
	gem_rx.rx_w_overflow <= 1'b0;

	if (!gem_rx.rx_resetn) begin
		rx_cur_buf_idx[0] <= 1'b1;
		rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-1:1] <= '0;
	end
	else begin
		if (gem_rx.rx_w_wr) begin
			rx_cur_buf_idx <= {
				rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-2:0],
				rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-1]
			};
		end
		if (gem_rx.rx_w_eop) begin
			rx_meta_fifo_w.wr_en <= rx_data_fifo_has_space_ff;
			rx_meta_fifo_w.wr_data <= gem_rx_w_status_encoded;

			rx_cur_buf_idx[0] <= 1'b1;
			rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-1:1] <= '0;
		end
		// If we have a full rx_buf_cur or this is the last write, store what we have
		// in the RX data FIFO.
		if (gem_rx.rx_w_eop || (gem_rx.rx_w_wr & rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-1])) begin
			rx_data_fifo_w.wr_en <= rx_data_fifo_has_space_ff;
			gem_rx.rx_w_overflow <= ~rx_data_fifo_has_space_ff & gem_rx.rx_w_eop;
		end
	end
end

/*
 * --------  --------  --------  --------
 * Clock Domain Crossing
 * --------  --------  --------  --------
 */
`ifdef VERILATOR
`else
xpm_fifo_async #(
	.CDC_SYNC_STAGES(2),
	.DOUT_RESET_VALUE("0"),
	.ECC_MODE("no_ecc"),
	.FIFO_MEMORY_TYPE("auto"),
	.FIFO_READ_LATENCY(0),
	.FIFO_WRITE_DEPTH(RX_META_FIFO_DEPTH),
	.FULL_RESET_VALUE(0),
	.PROG_EMPTY_THRESH(10),
	.PROG_FULL_THRESH(10),
	// Processor clock domain
	.RD_DATA_COUNT_WIDTH(RX_META_FIFO_RD_DATA_COUNT_WIDTH),
	.READ_DATA_WIDTH(RX_META_FIFO_WIDTH),
	.READ_MODE("fwft"),
	.RELATED_CLOCKS(0),
	.SIM_ASSERT_CHK(0),
	.USE_ADV_FEATURES("0707"),
	.WAKEUP_TIME(0),
	.WRITE_DATA_WIDTH(RX_META_FIFO_WIDTH),
	// GEM RX clock domain
	//.WR_DATA_COUNT_WIDTH(RX_META_FIFO_WR_DATA_COUNT_WIDTH)
	.WR_DATA_COUNT_WIDTH(1)
) rx_meta_fifo (
	// reset is synchronized to wr_clk!
	.rst(~gem_rx.rx_resetn),

	.rd_clk(clk),
	.rd_en(rx_meta_fifo_r.rd_en),
	.dout(rx_meta_fifo_r.rd_data),
	.empty(rx_meta_fifo_r.empty),
	.rd_data_count(rx_meta_fifo_w_rd_data_count),

	.wr_clk(gem_rx.rx_clock),
	.wr_en(rx_meta_fifo_w.wr_en),
	.din(rx_meta_fifo_w.wr_data),
	.full(rx_meta_fifo_w.full),
	.wr_data_count(rx_meta_fifo_w_wr_data_count)

	// for future reference:
	//
	//.almost_empty(almost_empty),
	//.almost_full(almost_full),
	//.data_valid(data_valid),
	//.dbiterr(dbiterr),
	//.overflow(overflow),
	//.prog_empty(prog_empty),
	//.prog_full(prog_full),
	//.rd_rst_busy(rd_rst_busy),
	//.sbiterr(sbiterr),
	//.underflow(underflow),
	//.wr_ack(wr_ack),
	//.wr_rst_busy(wr_rst_busy),
	//.injectdbiterr(injectdbiterr),
	//.injectsbiterr(injectsbiterr),
	//.sleep(sleep),
);
xpm_fifo_async #(
	.CDC_SYNC_STAGES(2),
	.DOUT_RESET_VALUE("0"),
	.ECC_MODE("no_ecc"),
	.FIFO_MEMORY_TYPE("auto"),
	.FIFO_READ_LATENCY(0),
	.FIFO_WRITE_DEPTH(RX_DATA_FIFO_DEPTH),
	.FULL_RESET_VALUE(0),
	.PROG_EMPTY_THRESH(10),
	.PROG_FULL_THRESH(10),
	// Processor clock domain
	.RD_DATA_COUNT_WIDTH(RX_DATA_FIFO_RD_DATA_COUNT_WIDTH),
	.READ_DATA_WIDTH(RX_DATA_FIFO_WIDTH),
	.READ_MODE("fwft"),
	.RELATED_CLOCKS(0),
	.SIM_ASSERT_CHK(0),
	.USE_ADV_FEATURES("0707"),
	.WAKEUP_TIME(0),
	.WRITE_DATA_WIDTH(RX_DATA_FIFO_WIDTH),
	// GEM RX clock domain
	//.WR_DATA_COUNT_WIDTH(1)
	.WR_DATA_COUNT_WIDTH(RX_DATA_FIFO_WR_DATA_COUNT_WIDTH)
) rx_data_fifo (
	// reset is synchronized to wr_clk!
	.rst(~gem_rx.rx_resetn),

	.wr_clk(gem_rx.rx_clock),
	.wr_en(rx_data_fifo_w.wr_en),
	.din(rx_data_fifo_w.wr_data),
	.wr_data_count(rx_data_fifo_w_wr_data_count),

	.rd_clk(clk),
	.rd_en(rx_data_fifo_r.rd_en),
	.dout(rx_data_fifo_r.rd_data),
	.rd_data_count(rx_data_fifo_r_rd_data_count)
);
`endif

fifo_to_axi #(
	.AXI_ADDR_WIDTH(32)
)
fifo_to_axi_0(
	.clock(clk),
	.reset_n(~rst),
	.mem_w(rx_data_mem_w),
	.fifo_r(rx_data_fifo_r),
	.axi_aw(m_axi_dma_aw),
	.axi_w(m_axi_dma_w),
	.axi_b(m_axi_dma_b)
);

endmodule
