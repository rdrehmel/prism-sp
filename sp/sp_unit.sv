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
module sp_unit #(
	parameter int RX_DATA_FIFO_SIZE,
	parameter int RX_DATA_FIFO_WIDTH,
	parameter int TX_DATA_FIFO_SIZE,
	parameter int TX_DATA_FIFO_WIDTH,
	parameter int USE_SP_UNIT_RX,
	parameter int USE_SP_UNIT_TX
) (
	input wire logic clk,
	input wire logic rst,
	input sp_inputs_t sp_inputs,
	unit_issue_interface.unit issue,
	unit_writeback_interface.unit wb,

	xpm_memory_tdpram_port_interface.master acpram_port_i,

	// For the GEM TX/RX subunits
	gem_rx_interface.slave gem_rx,
	gem_tx_interface.master gem_tx,

`ifdef RESURRECT_MON
	fifo_write_interface.monitor_out rx_data_fifo_write_mon,
	fifo_read_interface.monitor_out rx_data_fifo_read_mon,
`endif

	axi_write_address_channel.master m_axi_dma_aw,
	axi_write_channel.master m_axi_dma_w,
	axi_write_response_channel.master m_axi_dma_b,
	axi_read_address_channel.master m_axi_dma_ar,
	axi_read_channel.master m_axi_dma_r,

	// For the ACP subunit
	axi_write_address_channel.master m_axi_acp_aw,
	axi_write_channel.master m_axi_acp_w,
	axi_write_response_channel.master m_axi_acp_b,
	axi_read_address_channel.master m_axi_acp_ar,
	axi_read_channel.master m_axi_acp_r,

	// For the Common subunit
	mmr_readwrite_interface.master mmr_rw,
	mmr_read_interface.master mmr_r,
	mmr_intr_interface.master mmr_i
);

/*
 * --------  --------  --------  --------
 * PL Clock Domain
 * --------  --------  --------  --------
 */
`ifdef RESURRECT_MON
// Connect the monitor signals.
assign rx_data_fifo_read_mon.rd_en = rx_data_fifo_r.rd_en;
assign rx_data_fifo_read_mon.rd_data = rx_data_fifo_r.rd_data;
assign rx_data_fifo_write_mon.wr_en = rx_data_fifo_w.wr_en;
assign rx_data_fifo_write_mon.wr_data = rx_data_fifo_w.wr_data;
`endif

var id_t cur_id;
var logic [$bits(wb.rd)-1:0] tx_result;
var logic [$bits(wb.rd)-1:0] rx_result;
var logic [$bits(wb.rd)-1:0] common_result;
var logic [$bits(wb.rd)-1:0] acp_result;
var logic [$bits(wb.rd)-1:0] result;

/* Using wb.ack with this results in a UNOPTFLAT warning from verilator:
 *
 *   Signal unoptimizable: Feedback to clock or circular logic:
 *   'taiga_sim.cpu.register_file_and_writeback_block.unit_ack'
 */
assign issue.ready = ~|{acp_cmds_busy, common_cmds_busy, tx_cmds_busy, rx_cmds_busy};

/*
 * Binary to one-hot decoding of the current command.
 */
var logic [SP_UNIT_RX_NCMDS-1:0] rx_issue_cmd;
wire logic [SP_UNIT_RX_NCMDS-1:0] rx_cmds_busy;
wire logic [SP_UNIT_RX_NCMDS-1:0] rx_cmds_done;
var logic rx_issue_cmd_valid;

var logic [SP_UNIT_TX_NCMDS-1:0] tx_issue_cmd;
wire logic [SP_UNIT_TX_NCMDS-1:0] tx_cmds_busy;
wire logic [SP_UNIT_TX_NCMDS-1:0] tx_cmds_done;
var logic tx_issue_cmd_valid;

var logic [SP_UNIT_COMMON_NCMDS-1:0] common_issue_cmd;
wire logic [SP_UNIT_COMMON_NCMDS-1:0] common_cmds_busy;
wire logic [SP_UNIT_COMMON_NCMDS-1:0] common_cmds_done;
var logic common_issue_cmd_valid;

var logic [SP_UNIT_ACP_NCMDS-1:0] acp_issue_cmd;
wire logic [SP_UNIT_ACP_NCMDS-1:0] acp_cmds_busy;
wire logic [SP_UNIT_ACP_NCMDS-1:0] acp_cmds_done;
var logic acp_issue_cmd_valid;

always_comb begin
	rx_issue_cmd = '0;
	tx_issue_cmd = '0;
	common_issue_cmd = '0;
	acp_issue_cmd = '0;

	case (sp_inputs.fn7[4:0])
	//SP_FUNC7_RX_META_NELEMS: rx_issue_cmd[CMD_RX_META_NELEMS] = 1'b1;
	SP_FUNC7_RX_META_POP: rx_issue_cmd[CMD_RX_META_POP] = 1'b1;
	SP_FUNC7_RX_META_EMPTY: rx_issue_cmd[CMD_RX_META_EMPTY] = 1'b1;
	SP_FUNC7_RX_DATA_SKIP: rx_issue_cmd[CMD_RX_DATA_SKIP] = 1'b1;
	SP_FUNC7_RX_DATA_DMA_START: rx_issue_cmd[CMD_RX_DATA_DMA_START] = 1'b1;
	SP_FUNC7_RX_DATA_DMA_STATUS: rx_issue_cmd[CMD_RX_DATA_DMA_STATUS] = 1'b1;

	//SP_FUNC7_TX_META_NFREE: tx_issue_cmd[CMD_TX_META_NFREE] = 1'b1;
	SP_FUNC7_TX_META_PUSH: tx_issue_cmd[CMD_TX_META_PUSH] = 1'b1;
	SP_FUNC7_TX_META_FULL: tx_issue_cmd[CMD_TX_META_FULL] = 1'b1;
	SP_FUNC7_TX_DATA_COUNT: tx_issue_cmd[CMD_TX_DATA_COUNT] = 1'b1;
	SP_FUNC7_TX_DATA_DMA_START: tx_issue_cmd[CMD_TX_DATA_DMA_START] = 1'b1;
	SP_FUNC7_TX_DATA_DMA_STATUS: tx_issue_cmd[CMD_TX_DATA_DMA_STATUS] = 1'b1;

	SP_FUNC7_LOAD_REG: common_issue_cmd[CMD_LOAD_REG] = 1'b1;
	SP_FUNC7_STORE_REG: common_issue_cmd[CMD_STORE_REG] = 1'b1;
	SP_FUNC7_INTR: common_issue_cmd[CMD_INTR] = 1'b1;

	SP_FUNC7_ACP_READ_START: acp_issue_cmd[CMD_ACP_READ_START] = 1'b1;
	SP_FUNC7_ACP_READ_STATUS: acp_issue_cmd[CMD_ACP_READ_STATUS] = 1'b1;
	SP_FUNC7_ACP_WRITE_START: acp_issue_cmd[CMD_ACP_WRITE_START] = 1'b1;
	SP_FUNC7_ACP_WRITE_STATUS: acp_issue_cmd[CMD_ACP_WRITE_STATUS] = 1'b1;
	SP_FUNC7_ACP_SET_LOCAL_WSTRB: acp_issue_cmd[CMD_ACP_SET_LOCAL_WSTRB] = 1'b1;
	SP_FUNC7_ACP_SET_REMOTE_WSTRB: acp_issue_cmd[CMD_ACP_SET_REMOTE_WSTRB] = 1'b1;
	default: begin end
	endcase

	rx_issue_cmd_valid = 1'b0;
	tx_issue_cmd_valid = 1'b0;
	common_issue_cmd_valid = 1'b0;
	acp_issue_cmd_valid = 1'b0;

	case (sp_inputs.fn7[4:3])
	2'b00: rx_issue_cmd_valid = 1'b1;
	2'b01: tx_issue_cmd_valid = 1'b1;
	2'b10: common_issue_cmd_valid = 1'b1;
	2'b11: acp_issue_cmd_valid = 1'b1;
	endcase
end

/*
 * Response muxing.
 */
var logic cur_tx;
var logic cur_rx;
var logic cur_common;
var logic cur_acp;

assign wb.done = |{acp_cmds_done, common_cmds_done, rx_cmds_done, tx_cmds_done};
assign wb.id = cur_id;
assign wb.rd = result;

always_ff @(posedge clk) begin
	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready) begin
			cur_id <= issue.id;

			cur_rx <= rx_issue_cmd_valid;
			cur_tx <= tx_issue_cmd_valid;
			cur_common <= common_issue_cmd_valid;
			cur_acp <= acp_issue_cmd_valid;
		end
	end
end

always_comb begin
	result = '0;
	case (1'b1)
	cur_rx: result = rx_result;
	cur_tx: result = tx_result;
	cur_common: result = common_result;
	cur_acp: result = acp_result;
	endcase
end

if (USE_SP_UNIT_TX) begin
sp_unit_tx#(
	.TX_DATA_FIFO_SIZE(TX_DATA_FIFO_SIZE),
	.TX_DATA_FIFO_WIDTH(TX_DATA_FIFO_WIDTH),
	.RESULT_WIDTH($bits(wb.rd))
) sp_unit_tx_0(
	.clk,
	.rst,

	.sp_inputs,
	.issue,
	.wb,

	.issue_cmd(tx_issue_cmd),
	.cmds_busy(tx_cmds_busy),
	.cmds_done(tx_cmds_done),
	.result(tx_result),

	.m_axi_dma_ar,
	.m_axi_dma_r,

	.gem_tx
);
end
else begin
assign tx_cmds_busy = '0;
assign tx_cmds_done = '0;
end

if (USE_SP_UNIT_RX) begin
sp_unit_rx#(
	.RX_DATA_FIFO_SIZE(RX_DATA_FIFO_SIZE),
	.RX_DATA_FIFO_WIDTH(RX_DATA_FIFO_WIDTH),
	.RESULT_WIDTH($bits(wb.rd))
) sp_unit_rx_0(
	.clk,
	.rst,

	.sp_inputs,
	.issue,
	.wb,

	.issue_cmd(rx_issue_cmd),
	.cmds_busy(rx_cmds_busy),
	.cmds_done(rx_cmds_done),
	.result(rx_result),

	.m_axi_dma_aw,
	.m_axi_dma_w,
	.m_axi_dma_b,

	.gem_rx
);
end
else begin
assign rx_cmds_busy = '0;
assign rx_cmds_done = '0;
end

sp_unit_common#(
	.RESULT_WIDTH($bits(wb.rd))
) sp_unit_common_0(
	.clk,
	.rst,

	.sp_inputs,
	.issue,
	.wb,

	.issue_cmd(common_issue_cmd),
	.cmds_busy(common_cmds_busy),
	.cmds_done(common_cmds_done),
	.result(common_result),

	.mmr_rw,
	.mmr_r,
	.mmr_i
);

sp_unit_acp#(
	.RESULT_WIDTH($bits(wb.rd))
) sp_unit_acp_0(
	.clk,
	.rst,

	.sp_inputs,
	.issue,
	.wb,

	.issue_cmd(acp_issue_cmd),
	.cmds_busy(acp_cmds_busy),
	.cmds_done(acp_cmds_done),
	.result(acp_result),

	.acpram_port_i(acpram_port_i),
	.m_axi_acp_aw,
	.m_axi_acp_w,
	.m_axi_acp_b,
	.m_axi_acp_ar,
	.m_axi_acp_r
);

endmodule
