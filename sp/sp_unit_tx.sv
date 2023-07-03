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
module sp_unit_tx#(
	parameter int TX_DATA_FIFO_SIZE,
	parameter int TX_DATA_FIFO_WIDTH,
	parameter int RESULT_WIDTH
)
(
	input wire logic clk,
	input wire logic rst,

	input sp_inputs_t sp_inputs,
	unit_issue_interface.unit issue,
	unit_writeback_interface.unit wb,

	input wire logic [SP_UNIT_TX_NCMDS-1:0] issue_cmd,
	output wire logic [SP_UNIT_TX_NCMDS-1:0] cmds_busy,
	output wire logic [SP_UNIT_TX_NCMDS-1:0] cmds_done,
	output var logic [RESULT_WIDTH-1:0] result,

	axi_read_address_channel.master m_axi_dma_ar,
	axi_read_channel.master m_axi_dma_r,

	gem_tx_interface.master gem_tx
);

// This is currently redundant.
// But we might need it later in a transitional phase when both constants
// are made independent of each other.
if (m_axi_dma_r.AXI_RDATA_WIDTH != TX_DATA_FIFO_WIDTH) begin
	$error("We don't support m_axi_dma_r.AXI_RDATA_WIDTH != TX_DATA_FIFO_WIDTH)");
end

localparam int TX_META_FIFO_WIDTH = 32;
localparam int TX_META_FIFO_DEPTH = 2048;
localparam int TX_DATA_FIFO_DEPTH = TX_DATA_FIFO_SIZE / (TX_DATA_FIFO_WIDTH/8);

localparam int TX_META_FIFO_RD_DATA_COUNT_WIDTH = $clog2(TX_META_FIFO_DEPTH) + 1;
localparam int TX_META_FIFO_WR_DATA_COUNT_WIDTH = $clog2(TX_META_FIFO_DEPTH) + 1;
localparam int TX_DATA_FIFO_RD_DATA_COUNT_WIDTH = $clog2(TX_DATA_FIFO_DEPTH) + 1;
localparam int TX_DATA_FIFO_WR_DATA_COUNT_WIDTH = $clog2(TX_DATA_FIFO_DEPTH) + 1;

localparam int TX_META_DESC_NOCRC_BITN = 31;

if (TX_DATA_FIFO_WIDTH < 32) begin
	$error("We don't support a TX DATA FIFO width of less than 32.");
end

var logic [SP_UNIT_TX_NCMDS-1:0] cmds_busy_ff;
var logic [SP_UNIT_TX_NCMDS-1:0] cmds_busy_comb;
var logic [SP_UNIT_TX_NCMDS-1:0] cmds_done_ff;
var logic [SP_UNIT_TX_NCMDS-1:0] cmds_done_comb;
assign cmds_busy = cmds_busy_ff;
assign cmds_done = cmds_done_ff;

assign gem_tx.tx_r_flushed = '0;

/*
 * Interfaces for the TX meta FIFO
 */
fifo_read_interface #(
	.DATA_WIDTH(TX_META_FIFO_WIDTH)
) tx_meta_fifo_r();
wire logic [TX_META_FIFO_RD_DATA_COUNT_WIDTH-1:0] tx_meta_fifo_r_rd_data_count;

fifo_write_interface #(
	.DATA_WIDTH(TX_META_FIFO_WIDTH)
) tx_meta_fifo_w();
wire logic [TX_META_FIFO_WR_DATA_COUNT_WIDTH-1:0] tx_meta_fifo_w_wr_data_count;

/*
 * Interfaces for the TX data FIFO
 */
fifo_read_interface #(
	.DATA_WIDTH(TX_DATA_FIFO_WIDTH)
) tx_data_fifo_r();
wire logic [TX_DATA_FIFO_RD_DATA_COUNT_WIDTH-1:0] tx_data_fifo_r_rd_data_count;

fifo_write_interface #(
	.DATA_WIDTH(TX_DATA_FIFO_WIDTH)
) tx_data_fifo_w();
wire logic [TX_DATA_FIFO_WR_DATA_COUNT_WIDTH-1:0] tx_data_fifo_w_wr_data_count;

memory_read_interface #(
	.DATA_WIDTH(TX_DATA_FIFO_WIDTH),
	.ADDR_WIDTH(32)
) tx_data_mem_r();

/*
 * --------  --------  --------  --------
 * PL Clock Domain
 * --------  --------  --------  --------
 */
/*
 * Command "TX META PUSH"
 */
always_comb begin
	cmds_done_comb[CMD_TX_META_PUSH] = cmds_done_ff[CMD_TX_META_PUSH];
	cmds_busy_comb[CMD_TX_META_PUSH] = cmds_busy_ff[CMD_TX_META_PUSH];

	if (rst) begin
		cmds_done_comb[CMD_TX_META_PUSH] = 1'b0;
		cmds_busy_comb[CMD_TX_META_PUSH] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_META_PUSH]) begin
			cmds_done_comb[CMD_TX_META_PUSH] = 1'b1;
			cmds_busy_comb[CMD_TX_META_PUSH] = 1'b1;
		end
		if (cmds_done_ff[CMD_TX_META_PUSH] & wb.ack) begin
			cmds_done_comb[CMD_TX_META_PUSH] = 1'b0;
			cmds_busy_comb[CMD_TX_META_PUSH] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_TX_META_PUSH] <= cmds_done_comb[CMD_TX_META_PUSH];
	cmds_busy_ff[CMD_TX_META_PUSH] <= cmds_busy_comb[CMD_TX_META_PUSH];

	if (rst) begin
		tx_meta_fifo_w.wr_en <= 1'b0;
	end
	else begin
		// Unpulse
		tx_meta_fifo_w.wr_en <= 1'b0;

		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_META_PUSH]) begin
			tx_meta_fifo_w.wr_en <= 1'b1;
			tx_meta_fifo_w.wr_data <= sp_inputs.rs1;
		end
	end
end

/*
 * Command "TX META FULL"
 */
always_comb begin
	cmds_done_comb[CMD_TX_META_FULL] = cmds_done_ff[CMD_TX_META_FULL];
	cmds_busy_comb[CMD_TX_META_FULL] = cmds_busy_ff[CMD_TX_META_FULL];

	if (rst) begin
		cmds_done_comb[CMD_TX_META_FULL] = 1'b0;
		cmds_busy_comb[CMD_TX_META_FULL] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_META_FULL]) begin
			cmds_done_comb[CMD_TX_META_FULL] = 1'b1;
			cmds_busy_comb[CMD_TX_META_FULL] = 1'b1;
		end
		if (cmds_done_ff[CMD_TX_META_FULL] & wb.ack) begin
			cmds_done_comb[CMD_TX_META_FULL] = 1'b0;
			cmds_busy_comb[CMD_TX_META_FULL] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_TX_META_FULL] <= cmds_done_comb[CMD_TX_META_FULL];
	cmds_busy_ff[CMD_TX_META_FULL] <= cmds_busy_comb[CMD_TX_META_FULL];
end

/*
 * Command "TX DATA COUNT"
 */
always_comb begin
	cmds_done_comb[CMD_TX_DATA_COUNT] = cmds_done_ff[CMD_TX_DATA_COUNT];
	cmds_busy_comb[CMD_TX_DATA_COUNT] = cmds_busy_ff[CMD_TX_DATA_COUNT];

	if (rst) begin
		cmds_done_comb[CMD_TX_DATA_COUNT] = 1'b0;
		cmds_busy_comb[CMD_TX_DATA_COUNT] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_DATA_COUNT]) begin
			cmds_done_comb[CMD_TX_DATA_COUNT] = 1'b1;
			cmds_busy_comb[CMD_TX_DATA_COUNT] = 1'b1;
		end
		if (cmds_done_ff[CMD_TX_DATA_COUNT] & wb.ack) begin
			cmds_done_comb[CMD_TX_DATA_COUNT] = 1'b0;
			cmds_busy_comb[CMD_TX_DATA_COUNT] = 1'b0;
		end
	end
end

var logic [$bits(tx_data_fifo_w_wr_data_count)+$clog2(TX_DATA_FIFO_WIDTH/8)-1:0] tx_data_count_result_ff;

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_TX_DATA_COUNT] <= cmds_done_comb[CMD_TX_DATA_COUNT];
	cmds_busy_ff[CMD_TX_DATA_COUNT] <= cmds_busy_comb[CMD_TX_DATA_COUNT];

	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_DATA_COUNT]) begin
			tx_data_count_result_ff <= 32'({ tx_data_fifo_w_wr_data_count, {($clog2(TX_DATA_FIFO_WIDTH/8)){1'b0}} });
		end
	end
end

/*
 * Command "TX DATA DMA START"
 */
always_comb begin
	cmds_done_comb[CMD_TX_DATA_DMA_START] = cmds_done_ff[CMD_TX_DATA_DMA_START];
	cmds_busy_comb[CMD_TX_DATA_DMA_START] = cmds_busy_ff[CMD_TX_DATA_DMA_START];

	if (rst) begin
		cmds_done_comb[CMD_TX_DATA_DMA_START] = 1'b0;
		cmds_busy_comb[CMD_TX_DATA_DMA_START] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_DATA_DMA_START]) begin
			cmds_done_comb[CMD_TX_DATA_DMA_START] = 1'b1;
			cmds_busy_comb[CMD_TX_DATA_DMA_START] = 1'b1;
		end
		if (cmds_done_ff[CMD_TX_DATA_DMA_START] & wb.ack) begin
			cmds_done_comb[CMD_TX_DATA_DMA_START] = 1'b0;
			cmds_busy_comb[CMD_TX_DATA_DMA_START] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_TX_DATA_DMA_START] <= cmds_done_comb[CMD_TX_DATA_DMA_START];
	cmds_busy_ff[CMD_TX_DATA_DMA_START] <= cmds_busy_comb[CMD_TX_DATA_DMA_START];

	if (rst) begin
	end
	else begin
		tx_data_mem_r.start <= 1'b0;

		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_DATA_DMA_START]) begin
			tx_data_mem_r.start <= 1'b1;
			tx_data_mem_r.addr <= sp_inputs.rs1;
			tx_data_mem_r.len <= sp_inputs.rs2[15:0];
			tx_data_mem_r.cont <= sp_inputs.rs2[31];
		end
	end
end

/*
 * Command "TX DATA DMA STATUS"
 */
var logic tx_data_dma_status_result_ff;

always_comb begin
	cmds_done_comb[CMD_TX_DATA_DMA_STATUS] = cmds_done_ff[CMD_TX_DATA_DMA_STATUS];
	cmds_busy_comb[CMD_TX_DATA_DMA_STATUS] = cmds_busy_ff[CMD_TX_DATA_DMA_STATUS];

	if (rst) begin
		cmds_done_comb[CMD_TX_DATA_DMA_STATUS] = 1'b0;
		cmds_busy_comb[CMD_TX_DATA_DMA_STATUS] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_DATA_DMA_STATUS]) begin
			cmds_done_comb[CMD_TX_DATA_DMA_STATUS] = 1'b1;
			cmds_busy_comb[CMD_TX_DATA_DMA_STATUS] = 1'b1;
		end
		if (cmds_done_ff[CMD_TX_DATA_DMA_STATUS] & wb.ack) begin
			cmds_done_comb[CMD_TX_DATA_DMA_STATUS] = 1'b0;
			cmds_busy_comb[CMD_TX_DATA_DMA_STATUS] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_TX_DATA_DMA_STATUS] <= cmds_done_comb[CMD_TX_DATA_DMA_STATUS];
	cmds_busy_ff[CMD_TX_DATA_DMA_STATUS] <= cmds_busy_comb[CMD_TX_DATA_DMA_STATUS];

	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_TX_DATA_DMA_STATUS]) begin
			tx_data_dma_status_result_ff <= tx_data_mem_r.busy;
		end
	end
end

var logic [SP_UNIT_TX_NCMDS-1:0] cur_cmd;

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
	//cur_cmd[CMD_TX_META_NFREE]: result = 32'(tx_meta_nfree_comb);
	cur_cmd[CMD_TX_META_FULL]: result[0] = tx_meta_fifo_w.full;
	cur_cmd[CMD_TX_DATA_COUNT]: result = 31'(tx_data_count_result_ff);
	cur_cmd[CMD_TX_DATA_DMA_STATUS]: result[0] = tx_data_dma_status_result_ff;
	endcase
end

/*
 * --------  --------  --------  --------
 * GEM TX Interface Clock Domain
 * --------  --------  --------  --------
 */
localparam int TX_PACKET_BYTE_COUNT_WIDTH = 13;
var logic [TX_PACKET_BYTE_COUNT_WIDTH-1:0] tx_packet_byte_count_ff;
var logic [TX_PACKET_BYTE_COUNT_WIDTH-1:0] tx_packet_byte_count_comb;

// Only two states: idle (0) and not idle (1).
var logic tx_state = 1'b0;
var logic tx_last_byte_comb;

always_comb begin
	tx_packet_byte_count_comb = tx_packet_byte_count_ff;

	if (!gem_tx.tx_resetn) begin
		tx_packet_byte_count_comb = '0;
	end
	else begin
		if (~tx_state) begin
			if (~tx_meta_fifo_r.empty) begin
				tx_packet_byte_count_comb = tx_meta_fifo_r.rd_data[TX_PACKET_BYTE_COUNT_WIDTH-1:0];
			end
		end
		else begin
			if (gem_tx.tx_r_rd) begin
				tx_packet_byte_count_comb = tx_packet_byte_count_comb - 1;
			end
		end
	end
	tx_last_byte_comb = ~|tx_packet_byte_count_ff[$bits(tx_packet_byte_count_ff)-1:1] & tx_packet_byte_count_ff[0];
end

assign gem_tx.tx_r_err = 1'b0;
assign gem_tx.tx_r_underflow = 1'b0;

var logic [TX_DATA_FIFO_WIDTH-1:0] tx_cur_buf;
var logic [(TX_DATA_FIFO_WIDTH/8)-1:0] tx_cur_buf_valid;

always_ff @(posedge gem_tx.tx_clock) begin
	tx_packet_byte_count_ff <= tx_packet_byte_count_comb;

	if (!gem_tx.tx_resetn) begin
	end
	else begin
		// Unpulse
		gem_tx.tx_r_valid <= 1'b0;
		gem_tx.tx_r_eop <= 1'b0;
		tx_meta_fifo_r.rd_en <= 1'b0;
		tx_data_fifo_r.rd_en <= 1'b0;

		/*
		 * If there is a packet available.
		 */
		if (~tx_state) begin
			if (~tx_meta_fifo_r.empty) begin
				gem_tx.tx_r_data_rdy <= 1'b1;
				tx_state <= 1'b1;
				tx_meta_fifo_r.rd_en <= 1'b1;
				gem_tx.tx_r_control <= tx_meta_fifo_r.rd_data[TX_META_DESC_NOCRC_BITN];
				tx_data_fifo_r.rd_en <= 1'b1;
				tx_cur_buf <= tx_data_fifo_r.rd_data;
				tx_cur_buf_valid <= '1;

			end
		end
		else begin
			if (gem_tx.tx_r_rd) begin
				// The FIFO interface requests a word of information.

				gem_tx.tx_r_data_rdy <= 1'b0;
				gem_tx.tx_r_valid <= 1'b1;

				// Put the lower 8 bits from the TX buffer on the bus.
				gem_tx.tx_r_data <= tx_cur_buf[7:0];

				// If the TX buffer will be completely invalid after this
				// cycle, reload the buffer from the FWFT FIFO, pop the
				// element from the FIFO and update the "valid" register.
				if (|tx_cur_buf_valid[(TX_DATA_FIFO_WIDTH/8)-1:1] == 1'b0 &&
					tx_cur_buf_valid[0] == 1'b1)
				begin
					tx_cur_buf <= tx_data_fifo_r.rd_data;
					tx_cur_buf_valid <= '1;
					tx_data_fifo_r.rd_en <= ~tx_last_byte_comb;
				end
				else begin
					// Shift the TX buffer right by 8 bits.
					// Shift the TX buffer valid bits right by 1 bit.
					tx_cur_buf <= { 8'h00, tx_cur_buf[TX_DATA_FIFO_WIDTH-1:8] };
					tx_cur_buf_valid <= { 1'b0, tx_cur_buf_valid[(TX_DATA_FIFO_WIDTH/8)-1:1] };
				end

				// This is more like a resource utilization hack.
				// We used tx_r_data_rdy to tx_r_sop because we know
				// it will be 1'b1 only the first time we come around
				// here.
				gem_tx.tx_r_sop <= gem_tx.tx_r_data_rdy;
				gem_tx.tx_r_eop <= tx_last_byte_comb;
				tx_state <= ~tx_last_byte_comb;
			end
		end
	end
end

var logic gem_dma_tx_end_tog_prev;

always_ff @(posedge gem_tx.tx_clock) begin
	gem_dma_tx_end_tog_prev <= gem_tx.dma_tx_end_tog;

	if (!gem_tx.tx_resetn) begin
	end
	else begin
		if (gem_dma_tx_end_tog_prev != gem_tx.dma_tx_end_tog) begin
			// Could add tx_r_status to the TX result FIFO here.
			gem_tx.dma_tx_status_tog <= gem_tx.dma_tx_end_tog;
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
	.FIFO_WRITE_DEPTH(TX_META_FIFO_DEPTH),
	.FULL_RESET_VALUE(0),
	.PROG_EMPTY_THRESH(10),
	.PROG_FULL_THRESH(10),
	// GEM TX clock domain
	//.RD_DATA_COUNT_WIDTH(TX_META_FIFO_RD_DATA_COUNT_WIDTH),
	.RD_DATA_COUNT_WIDTH(1),
	.READ_DATA_WIDTH(TX_META_FIFO_WIDTH),
	.READ_MODE("fwft"),
	.RELATED_CLOCKS(0),
	.SIM_ASSERT_CHK(0),
	.USE_ADV_FEATURES("0707"),
	.WAKEUP_TIME(0),
	.WRITE_DATA_WIDTH(TX_META_FIFO_WIDTH),
	// Processor clock domain
	.WR_DATA_COUNT_WIDTH(TX_META_FIFO_WR_DATA_COUNT_WIDTH)
) tx_meta_fifo (
	// reset is synchronized to wr_clk!
	.rst(rst),

	.rd_clk(gem_tx.tx_clock),
	.rd_en(tx_meta_fifo_r.rd_en),
	.dout(tx_meta_fifo_r.rd_data),
	.empty(tx_meta_fifo_r.empty),
	.rd_data_count(tx_meta_fifo_r_rd_data_count), 

	.wr_clk(clk),
	.wr_en(tx_meta_fifo_w.wr_en),
	.din(tx_meta_fifo_w.wr_data),
	.full(tx_meta_fifo_w.full),
	.wr_data_count(tx_meta_fifo_w_wr_data_count)
);
xpm_fifo_async #(
	.CDC_SYNC_STAGES(2),
	.DOUT_RESET_VALUE("0"),
	.ECC_MODE("no_ecc"),
	.FIFO_MEMORY_TYPE("auto"),
	.FIFO_READ_LATENCY(0),
	.FIFO_WRITE_DEPTH(TX_DATA_FIFO_DEPTH),
	.FULL_RESET_VALUE(0),
	.PROG_EMPTY_THRESH(10),
	.PROG_FULL_THRESH(10),
	// GEM TX clock domain
	//.RD_DATA_COUNT_WIDTH(TX_DATA_FIFO_RD_DATA_COUNT_WIDTH),
	.RD_DATA_COUNT_WIDTH(1),
	.READ_DATA_WIDTH(TX_DATA_FIFO_WIDTH),
	.READ_MODE("fwft"),
	.RELATED_CLOCKS(0),
	.SIM_ASSERT_CHK(0),
	.USE_ADV_FEATURES("0707"),
	.WAKEUP_TIME(0),
	.WRITE_DATA_WIDTH(TX_DATA_FIFO_WIDTH),
	// Processor clock domain
	.WR_DATA_COUNT_WIDTH(TX_DATA_FIFO_WR_DATA_COUNT_WIDTH)
) tx_data_fifo (
	// reset is synchronized to wr_clk!
	.rst(rst),

	.wr_clk(clk),
	.wr_en(tx_data_fifo_w.wr_en),
	.din(tx_data_fifo_w.wr_data),
	.wr_data_count(tx_data_fifo_w_wr_data_count),

	.rd_clk(gem_tx.tx_clock),
	.rd_en(tx_data_fifo_r.rd_en),
	.dout(tx_data_fifo_r.rd_data),
	.rd_data_count(tx_data_fifo_r_rd_data_count)
);
`endif

axi_to_fifo #(
	.AXI_ADDR_WIDTH(32)
)
axi_to_fifo_0(
	.clock(clk),
	.reset_n(~rst),
	.mem_r(tx_data_mem_r),
	.fifo_w(tx_data_fifo_w),
	.axi_ar(m_axi_dma_ar),
	.axi_r(m_axi_dma_r)
);
endmodule
