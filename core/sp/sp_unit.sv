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
module sp_unit(
	input wire logic clk,
	input wire logic rst,
	output wire logic gem_irq,
	input sp_inputs_t sp_inputs,
	unit_issue_interface.unit issue,
	unit_writeback_interface.unit wb,
	gem_interface.slave gem,
	fifo_write_interface.monitor_out rx_data_fifo_write_mon,
	fifo_read_interface.monitor_out rx_data_fifo_read_mon,

	axi_write_address_channel.master m_axi_dma_aw,
	axi_write_channel.master m_axi_dma_w,
	axi_write_response_channel.master m_axi_dma_b,

	axi_read_address_channel.master m_axi_dma_ar,
	axi_read_channel.master m_axi_dma_r,

	mmr_readwrite_interface.master mmr_rw,
	mmr_read_interface.master mmr_r,

	output wire logic [12:0] tx_packet_byte_count,
	output wire logic [15:0] tx_data_fifo_wr_data_count_
);

/* Descriptions are taken from the Xilinx UG1085
 */
localparam int IRQ_PULSE_NCYCLES = 10;

// RX
localparam int RX_META_FIFO_WIDTH = 32;
localparam int RX_META_FIFO_DEPTH = 64;
// SIZE in bytes
localparam int RX_DATA_FIFO_WIDTH = 32;
localparam int RX_DATA_FIFO_SIZE = 2**16;
localparam int RX_DATA_FIFO_DEPTH = RX_DATA_FIFO_SIZE / RX_DATA_FIFO_WIDTH;

localparam int RX_META_FIFO_RD_DATA_COUNT_WIDTH = $clog2(RX_META_FIFO_DEPTH) + 1;
localparam int RX_META_FIFO_WR_DATA_COUNT_WIDTH = $clog2(RX_META_FIFO_DEPTH) + 1;
localparam int RX_DATA_FIFO_RD_DATA_COUNT_WIDTH = $clog2(RX_DATA_FIFO_DEPTH) + 1;
localparam int RX_DATA_FIFO_WR_DATA_COUNT_WIDTH = $clog2(RX_DATA_FIFO_DEPTH) + 1;

// TX
localparam int TX_META_FIFO_WIDTH = 32;
localparam int TX_META_FIFO_DEPTH = 64;
// SIZE in bytes
localparam int TX_DATA_FIFO_WIDTH = 32;
localparam int TX_DATA_FIFO_SIZE = 2**16;
localparam int TX_DATA_FIFO_DEPTH = TX_DATA_FIFO_SIZE / TX_DATA_FIFO_WIDTH;

localparam int TX_META_FIFO_RD_DATA_COUNT_WIDTH = $clog2(TX_META_FIFO_DEPTH) + 1;
localparam int TX_META_FIFO_WR_DATA_COUNT_WIDTH = $clog2(TX_META_FIFO_DEPTH) + 1;
localparam int TX_DATA_FIFO_RD_DATA_COUNT_WIDTH = $clog2(TX_DATA_FIFO_DEPTH) + 1;
localparam int TX_DATA_FIFO_WR_DATA_COUNT_WIDTH = $clog2(TX_DATA_FIFO_DEPTH) + 1;

if (TX_DATA_FIFO_WIDTH < 32) begin
	$error("We don't support a TX DATA FIFO width of less than 32.");
end

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
	SP_FUNC7_TX_DATA_SKIP		= 5'b01100,
	SP_FUNC7_TX_DATA_DMA_START	= 5'b01101,
	SP_FUNC7_TX_DATA_DMA_STATUS	= 5'b01110,

	SP_FUNC7_LOAD_REG			= 5'b10000,
	SP_FUNC7_STORE_REG			= 5'b10001,
	SP_FUNC7_PULSE				= 5'b11111
} sp_func7_t;

localparam int CMD_RX_META_NELEMS		= 0;
localparam int CMD_RX_META_POP			= CMD_RX_META_NELEMS + 1;
localparam int CMD_RX_META_EMPTY		= CMD_RX_META_POP + 1;
localparam int CMD_RX_DATA_SKIP			= CMD_RX_META_EMPTY + 1;
localparam int CMD_RX_DATA_DMA_START	= CMD_RX_DATA_SKIP + 1;
localparam int CMD_RX_DATA_DMA_STATUS	= CMD_RX_DATA_DMA_START + 1;

localparam int CMD_TX_META_NFREE		= CMD_RX_DATA_DMA_STATUS + 1;
localparam int CMD_TX_META_PUSH			= CMD_TX_META_NFREE + 1;
localparam int CMD_TX_META_FULL			= CMD_TX_META_PUSH + 1;
localparam int CMD_TX_DATA_SKIP			= CMD_TX_META_FULL + 1;
localparam int CMD_TX_DATA_DMA_START	= CMD_TX_DATA_SKIP + 1;
localparam int CMD_TX_DATA_DMA_STATUS	= CMD_TX_DATA_DMA_START + 1;

localparam int CMD_LOAD_REG				= CMD_TX_DATA_DMA_STATUS + 1;
localparam int CMD_STORE_REG			= CMD_LOAD_REG + 1;

localparam int CMD_PULSE				= CMD_STORE_REG + 1;

localparam int NCMDS = CMD_PULSE + 1;

/*
 * Interfaces for the RX meta FIFO
 */
fifo_read_interface #(
	.DATA_WIDTH(RX_META_FIFO_WIDTH)
) rx_meta_fifo_r();
var logic [RX_META_FIFO_RD_DATA_COUNT_WIDTH-1:0] rx_meta_fifo_r_rd_data_count;

fifo_write_interface #(
	.DATA_WIDTH(RX_META_FIFO_WIDTH)
) rx_meta_fifo_w();
var logic [RX_META_FIFO_WR_DATA_COUNT_WIDTH-1:0] rx_meta_fifo_w_wr_data_count;

/*
 * Interfaces for the RX data FIFO
 */
fifo_read_interface #(
	.DATA_WIDTH(RX_DATA_FIFO_WIDTH)
) rx_data_fifo_r();
var logic [RX_DATA_FIFO_RD_DATA_COUNT_WIDTH-1:0] rx_data_fifo_r_rd_data_count;

fifo_write_interface #(
	.DATA_WIDTH(RX_DATA_FIFO_WIDTH)
) rx_data_fifo_w();
var logic [RX_DATA_FIFO_WR_DATA_COUNT_WIDTH-1:0] rx_data_fifo_w_wr_data_count;

memory_write_interface #(
	.DATA_WIDTH(RX_DATA_FIFO_WIDTH),
	.ADDR_WIDTH(32)
) rx_data_mem_w();

/*
 * Interfaces for the TX meta FIFO
 */
fifo_read_interface #(
	.DATA_WIDTH(TX_META_FIFO_WIDTH)
) tx_meta_fifo_r();
var logic [TX_META_FIFO_RD_DATA_COUNT_WIDTH-1:0] tx_meta_fifo_r_rd_data_count;

fifo_write_interface #(
	.DATA_WIDTH(TX_META_FIFO_WIDTH)
) tx_meta_fifo_w();
var logic [TX_META_FIFO_WR_DATA_COUNT_WIDTH-1:0] tx_meta_fifo_w_wr_data_count;

/*
 * Interfaces for the TX data FIFO
 */
fifo_read_interface #(
	.DATA_WIDTH(TX_DATA_FIFO_WIDTH)
) tx_data_fifo_r();
var logic [TX_DATA_FIFO_RD_DATA_COUNT_WIDTH-1:0] tx_data_fifo_r_rd_data_count;

fifo_write_interface #(
	.DATA_WIDTH(TX_DATA_FIFO_WIDTH)
) tx_data_fifo_w();
var logic [TX_DATA_FIFO_WR_DATA_COUNT_WIDTH-1:0] tx_data_fifo_w_wr_data_count;
assign tx_data_fifo_wr_data_count_ = 16'(tx_data_fifo_w_wr_data_count);

memory_read_interface #(
	.DATA_WIDTH(TX_DATA_FIFO_WIDTH),
	.ADDR_WIDTH(32)
) tx_data_mem_r();

/*
 * --------  --------  --------  --------
 * PL Clock Domain
 * --------  --------  --------  --------
 */
// Connect the monitor signals.
assign rx_data_fifo_read_mon.rd_en = rx_data_fifo_r.rd_en;
assign rx_data_fifo_read_mon.rd_data = rx_data_fifo_r.rd_data;
assign rx_data_fifo_write_mon.wr_en = rx_data_fifo_w.wr_en;
assign rx_data_fifo_write_mon.wr_data = rx_data_fifo_w.wr_data;

var id_t cur_id;
var logic [NCMDS-1:0] cur_cmd;

var logic [$bits(wb.rd)-1:0] result;
var logic [NCMDS-1:0] cmds_busy_comb;
var logic [NCMDS-1:0] cmds_busy_ff;
var logic [NCMDS-1:0] cmds_done_comb;
var logic [NCMDS-1:0] cmds_done_ff;

/* Using wb.ack with this results in a UNOPTFLAT warning from verilator:
 *
 *   Signal unoptimizable: Feedback to clock or circular logic:
 *   'taiga_sim.cpu.register_file_and_writeback_block.unit_ack'
 */
assign issue.ready = ~|cmds_busy_ff;

/*
 * Binary to one-hot decoding of the current command.
 */
var logic [NCMDS-1:0] issue_cmd;
always_comb begin
	issue_cmd = '0;

	case (sp_inputs.fn7[4:0])
	//SP_FUNC7_RX_META_NELEMS: issue_cmd[CMD_RX_META_NELEMS] = 1'b1;
	SP_FUNC7_RX_META_POP: issue_cmd[CMD_RX_META_POP] = 1'b1;
	SP_FUNC7_RX_META_EMPTY: issue_cmd[CMD_RX_META_EMPTY] = 1'b1;
	SP_FUNC7_RX_DATA_SKIP: issue_cmd[CMD_RX_DATA_SKIP] = 1'b1;
	SP_FUNC7_RX_DATA_DMA_START: issue_cmd[CMD_RX_DATA_DMA_START] = 1'b1;
	SP_FUNC7_RX_DATA_DMA_STATUS: issue_cmd[CMD_RX_DATA_DMA_STATUS] = 1'b1;
	//SP_FUNC7_TX_META_NFREE: issue_cmd[CMD_TX_META_NFREE] = 1'b1;
	SP_FUNC7_TX_META_PUSH: issue_cmd[CMD_TX_META_PUSH] = 1'b1;
	SP_FUNC7_TX_META_FULL: issue_cmd[CMD_TX_META_FULL] = 1'b1;
	SP_FUNC7_TX_DATA_DMA_START: issue_cmd[CMD_TX_DATA_DMA_START] = 1'b1;
	SP_FUNC7_TX_DATA_DMA_STATUS: issue_cmd[CMD_TX_DATA_DMA_STATUS] = 1'b1;
	SP_FUNC7_STORE_REG: issue_cmd[CMD_STORE_REG] = 1'b1;
	SP_FUNC7_LOAD_REG: issue_cmd[CMD_LOAD_REG] = 1'b1;
	SP_FUNC7_PULSE: issue_cmd[CMD_PULSE] = 1'b1;
	default: begin end
	endcase
end

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
			// XXX skip!
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
		if (issue.new_request & issue.ready & issue_cmd[CMD_RX_DATA_DMA_STATUS]) begin
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

var logic [31:0] load_reg_cur;

/*
 * Command "LOAD REG"
 */
always_comb begin
	cmds_done_comb[CMD_LOAD_REG] = cmds_done_ff[CMD_LOAD_REG];
	cmds_busy_comb[CMD_LOAD_REG] = cmds_busy_ff[CMD_LOAD_REG];

	if (rst) begin
		cmds_done_comb[CMD_LOAD_REG] = 1'b0;
		cmds_busy_comb[CMD_LOAD_REG] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_LOAD_REG]) begin
			cmds_done_comb[CMD_LOAD_REG] = 1'b1;
			cmds_busy_comb[CMD_LOAD_REG] = 1'b1;
		end
		if (cmds_done_ff[CMD_LOAD_REG] & wb.ack) begin
			cmds_done_comb[CMD_LOAD_REG] = 1'b0;
			cmds_busy_comb[CMD_LOAD_REG] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_LOAD_REG] <= cmds_done_comb[CMD_LOAD_REG];
	cmds_busy_ff[CMD_LOAD_REG] <= cmds_busy_comb[CMD_LOAD_REG];

	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_LOAD_REG]) begin
			if (sp_inputs.rs1[MMR_R_BITN]) begin
				if (mmr_r.INDEX_WIDTH == 0)
					load_reg_cur <= mmr_r.data[0];
				else
					load_reg_cur <= mmr_r.data[sp_inputs.rs1[0 +: mmr_r.INDEX_WIDTH]];
			end
			else begin
				if (mmr_rw.INDEX_WIDTH == 0)
					load_reg_cur <= mmr_rw.data[0];
				else
					load_reg_cur <= mmr_rw.data[sp_inputs.rs1[0 +: mmr_rw.INDEX_WIDTH]];
			end
		end
	end
end

/*
 * Command "STORE REG"
 */
always_comb begin
	cmds_done_comb[CMD_STORE_REG] = cmds_done_ff[CMD_STORE_REG];
	cmds_busy_comb[CMD_STORE_REG] = cmds_busy_ff[CMD_STORE_REG];

	if (rst) begin
		cmds_done_comb[CMD_STORE_REG] = 1'b0;
		cmds_busy_comb[CMD_STORE_REG] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_STORE_REG]) begin
			cmds_done_comb[CMD_STORE_REG] = 1'b1;
			cmds_busy_comb[CMD_STORE_REG] = 1'b1;
		end
		if (cmds_done_ff[CMD_STORE_REG] & wb.ack) begin
			cmds_done_comb[CMD_STORE_REG] = 1'b0;
			cmds_busy_comb[CMD_STORE_REG] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_STORE_REG] <= cmds_done_comb[CMD_STORE_REG];
	cmds_busy_ff[CMD_STORE_REG] <= cmds_busy_comb[CMD_STORE_REG];

	if (rst) begin
		mmr_rw.store <= 1'b0;
	end
	else begin
		// Unpulse
		mmr_rw.store <= 1'b0;

		if (issue.new_request & issue.ready & issue_cmd[CMD_STORE_REG]) begin
			mmr_rw.store <= 1'b1;
			if (mmr_rw.INDEX_WIDTH == 0)
				mmr_rw.store_idx <= 0;
			else begin
				mmr_rw.store_idx <= sp_inputs.rs1[0 +:mmr_rw.INDEX_WIDTH];
			end
			mmr_rw.store_data <= sp_inputs.rs2;
		end
	end
end

/*
 * Command "PULSE"
 */
always_comb begin
	cmds_done_comb[CMD_PULSE] = cmds_done_ff[CMD_PULSE];
	cmds_busy_comb[CMD_PULSE] = cmds_busy_ff[CMD_PULSE];

	if (rst) begin
		cmds_done_comb[CMD_PULSE] = 1'b0;
		cmds_busy_comb[CMD_PULSE] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_PULSE]) begin
			cmds_done_comb[CMD_PULSE] = 1'b1;
			cmds_busy_comb[CMD_PULSE] = 1'b1;
		end
		if (cmds_done_ff[CMD_PULSE] & wb.ack) begin
			cmds_done_comb[CMD_PULSE] = 1'b0;
			cmds_busy_comb[CMD_PULSE] = 1'b0;
		end
	end
end

var logic [IRQ_PULSE_NCYCLES-1:0] gem_irq_;
assign gem_irq = |gem_irq_;

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_PULSE] <= cmds_done_comb[CMD_PULSE];
	cmds_busy_ff[CMD_PULSE] <= cmds_busy_comb[CMD_PULSE];

	if (rst) begin
		gem_irq_ <= '0;
	end
	else begin
		// Shift the register left by one.
		gem_irq_ <= { gem_irq_[IRQ_PULSE_NCYCLES-2:0], 1'b0 };

		if (issue.new_request & issue.ready & issue_cmd[CMD_PULSE]) begin
			gem_irq_[0] <= 1'b1;
		end
	end
end

/*
 * Response muxing.
 */
always_comb begin
	result = '0;

	// "Reverse case" statement for one-hot encoding.
	case (1'b1)
	//cur_cmd[CMD_RX_META_NELEMS]: result = 32'(rx_meta_nelems_comb);
	cur_cmd[CMD_RX_META_POP]: result = rx_meta_fifo_read_rd_data;
	cur_cmd[CMD_RX_META_EMPTY]: result[0] = rx_meta_fifo_r.empty;
	cur_cmd[CMD_RX_DATA_DMA_STATUS]: result[0] = rx_data_dma_status_result_ff;

	//cur_cmd[CMD_TX_META_NFREE]: result = 32'(tx_meta_nfree_comb);
	cur_cmd[CMD_TX_META_FULL]: result[0] = tx_meta_fifo_w.full;
	cur_cmd[CMD_TX_DATA_DMA_STATUS]: result[0] = tx_data_dma_status_result_ff;
	cur_cmd[CMD_LOAD_REG]: result = load_reg_cur;
	endcase
end

assign wb.done = |cmds_done_ff;
assign wb.id = cur_id;
assign wb.rd = result;

always_ff @(posedge clk) begin
	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready) begin
			cur_id <= issue.id;
			cur_cmd <= issue_cmd;
		end
	end
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

	if (!gem.rx_resetn) begin
		rx_packet_byte_count_comb = '0;
	end
	else begin
		if (gem.rx_w_sop) begin
			rx_packet_byte_count_comb = '0;
		end
		if (gem.rx_w_wr) begin
			rx_packet_byte_count_comb = rx_packet_byte_count_comb + 1;
		end
	end
end

var logic [31:0] gem_rx_w_status_encoded;

gem_rx_w_status_encoder gem_rx_w_status_encoder_inst(
	.rx_w_status(gem.rx_w_status),
	.frame_length(rx_packet_byte_count_comb),
	.out(gem_rx_w_status_encoded)
);

var logic [RX_DATA_FIFO_WIDTH-1:0] rx_cur_buf_comb;
var logic [RX_DATA_FIFO_WIDTH-1:0] rx_cur_buf_ff;
// A bit that is set represents a byte that is not valid.
var logic [(RX_DATA_FIFO_WIDTH/8)-1:0] rx_cur_buf_idx;

always_comb begin
	rx_cur_buf_comb = rx_cur_buf_ff;

	if (!gem.rx_resetn) begin
	end
	else begin
		if (gem.rx_w_sop) begin
			rx_cur_buf_comb = '0;
		end
		if (gem.rx_w_wr) begin
			// Reset the buffer for data security/privacy reasons
			if (rx_cur_buf_idx[0]) begin
				rx_cur_buf_comb[RX_DATA_FIFO_WIDTH-1:8] = '0;
			end
			// Put the current data into the correct slot.
			for (int i = 0; i < RX_DATA_FIFO_WIDTH/8; i++) begin
				if (rx_cur_buf_idx[i]) begin
					rx_cur_buf_comb[i*8 +:8] = gem.rx_w_data[7:0];
				end
			end
		end
	end
end

assign rx_data_fifo_w.wr_data = rx_cur_buf_ff;

always_ff @(posedge gem.rx_clock) begin
	rx_cur_buf_ff <= rx_cur_buf_comb;
	rx_packet_byte_count_ff <= rx_packet_byte_count_comb;

	// Unpulse
	rx_meta_fifo_w.wr_en <= 1'b0;
	rx_data_fifo_w.wr_en <= 1'b0;

	if (!gem.rx_resetn) begin
		rx_cur_buf_idx[0] <= 1'b1;
		rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-1:1] <= '0;
	end
	else begin
		if (gem.rx_w_wr) begin
			rx_cur_buf_idx <= {
				rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-2:0],
				rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-1]
			};
		end
		if (gem.rx_w_eop) begin
			rx_meta_fifo_w.wr_en <= 1'b1;
			rx_meta_fifo_w.wr_data <= gem_rx_w_status_encoded;

			rx_cur_buf_idx[0] <= 1'b1;
			rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-1:1] <= '0;
		end
		if (gem.rx_w_eop || (gem.rx_w_wr & rx_cur_buf_idx[(RX_DATA_FIFO_WIDTH/8)-1])) begin
			rx_data_fifo_w.wr_en <= 1'b1;
		end
	end
end

/*
 * --------  --------  --------  --------
 * GEM TX Interface Clock Domain
 * --------  --------  --------  --------
 */
localparam int TX_PACKET_BYTE_COUNT_WIDTH = 13;
var logic [TX_PACKET_BYTE_COUNT_WIDTH-1:0] tx_packet_byte_count_ff;
var logic [TX_PACKET_BYTE_COUNT_WIDTH-1:0] tx_packet_byte_count_comb;
assign tx_packet_byte_count = tx_packet_byte_count_ff;

// Only two states: idle (0) and not idle (1).
var logic tx_state = 1'b0;

always_comb begin
	tx_packet_byte_count_comb = tx_packet_byte_count_ff;

	if (!gem.tx_resetn) begin
		tx_packet_byte_count_comb = '0;
	end
	else begin
		if (~tx_state) begin
			if (~tx_meta_fifo_r.empty) begin
				tx_packet_byte_count_comb = tx_meta_fifo_r.rd_data[TX_PACKET_BYTE_COUNT_WIDTH-1:0];
			end
		end
		else begin
			if (gem.tx_r_rd) begin
				tx_packet_byte_count_comb = tx_packet_byte_count_comb - 1;
			end
		end
	end
end

assign gem.tx_r_err = 1'b0;
assign gem.tx_r_underflow = 1'b0;

var logic [TX_DATA_FIFO_WIDTH-1:0] tx_cur_buf;
var logic [(TX_DATA_FIFO_WIDTH/8)-1:0] tx_cur_buf_valid;

always_ff @(posedge gem.tx_clock) begin
	tx_packet_byte_count_ff <= tx_packet_byte_count_comb;

	if (!gem.tx_resetn) begin
	end
	else begin
		// Unpulse
		gem.tx_r_valid <= 1'b0;
		tx_meta_fifo_r.rd_en <= 1'b0;
		tx_data_fifo_r.rd_en <= 1'b0;

		/*
		 * If there is a packet available.
		 */
		if (~tx_state) begin
			if (~tx_meta_fifo_r.empty) begin
				gem.tx_r_data_rdy <= 1'b1;
				tx_state <= 1'b1;
				tx_meta_fifo_r.rd_en <= 1'b1;
				tx_data_fifo_r.rd_en <= 1'b1;
				tx_cur_buf <= tx_data_fifo_r.rd_data;
				tx_cur_buf_valid <= '1;
			end
		end
		else begin
			if (gem.tx_r_rd) begin
				// The FIFO interface requests a word of information.

				gem.tx_r_data_rdy <= 1'b0;
				gem.tx_r_valid <= 1'b1;

				// Put the lower 8 bits from the TX buffer on the bus.
				gem.tx_r_data <= tx_cur_buf[7:0];

				// If the TX buffer will be completely invalid after this
				// cycle, reload the buffer from the FWFT FIFO, pop the
				// element from the FIFO and update the "valid" register.
				if (|tx_cur_buf_valid[(TX_DATA_FIFO_WIDTH/8)-1:1] == 1'b0 &&
					tx_cur_buf_valid[0] == 1'b1)
				begin
					tx_cur_buf <= tx_data_fifo_r.rd_data;
					tx_cur_buf_valid <= '1;
					tx_data_fifo_r.rd_en <= 1'b1;
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
				gem.tx_r_sop <= gem.tx_r_data_rdy;

				if (tx_packet_byte_count_comb == '0) begin
					gem.tx_r_eop <= 1'b1;
					tx_state <= 1'b0;
				end
				else begin
					gem.tx_r_eop <= 1'b0;
				end
			end
		end
	end
end

var logic gem_dma_tx_end_tog_prev;

always_ff @(posedge gem.tx_clock) begin
	gem_dma_tx_end_tog_prev <= gem.dma_tx_end_tog;

	if (!gem.tx_resetn) begin
	end
	else begin
		if (gem_dma_tx_end_tog_prev != gem.dma_tx_end_tog) begin
			// Could add tx_r_status to the TX result FIFO here.
			gem.dma_tx_status_tog <= gem.dma_tx_end_tog;
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
	.rst(rst),

	.rd_clk(clk),
	.rd_en(rx_meta_fifo_r.rd_en),
	.dout(rx_meta_fifo_r.rd_data),
	.empty(rx_meta_fifo_r.empty),
	.rd_data_count(rx_meta_fifo_w_rd_data_count),

	.wr_clk(gem.rx_clock),
	.wr_en(rx_meta_fifo_w.wr_en),
	.din(rx_meta_fifo_w.wr_data),
	.full(rx_meta_fifo_w.full)
	//.wr_data_count(rx_meta_fifo_w_wr_data_count)

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
	.rst(rst),

	.wr_clk(gem.rx_clock),
	.wr_en(rx_data_fifo_w.wr_en),
	.din(rx_data_fifo_w.wr_data),
	//.wr_data_count(rx_data_fifo_w_wr_data_count)

	.rd_clk(clk),
	.rd_en(rx_data_fifo_r.rd_en),
	.dout(rx_data_fifo_r.rd_data),
	.rd_data_count(rx_data_fifo_r_rd_data_count)
);
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
	// XXX sure? or do we need a reset in the GEM TX clock domain?
	.rst(rst),

	.rd_clk(gem.tx_clock),
	.rd_en(tx_meta_fifo_r.rd_en),
	.dout(tx_meta_fifo_r.rd_data),
	.empty(tx_meta_fifo_r.empty),
	//.rd_data_count(tx_meta_fifo_r_rd_data_count),

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
	// XXX sure? or do we need a reset in the GEM TX clock domain?
	.rst(rst),

	.wr_clk(clk),
	.wr_en(tx_data_fifo_w.wr_en),
	.din(tx_data_fifo_w.wr_data),
	.wr_data_count(tx_data_fifo_w_wr_data_count),

	.rd_clk(gem.tx_clock),
	.rd_en(tx_data_fifo_r.rd_en),
	.dout(tx_data_fifo_r.rd_data)
	//.rd_data_count(tx_data_fifo_r_rd_data_count)
);
`endif

fifo_to_axi #(
	.AXI_ADDR_WIDTH(32),
	.AXI_DATA_WIDTH(32)
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

axi_to_fifo #(
	.AXI_ADDR_WIDTH(32),
	.AXI_DATA_WIDTH(32)
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
