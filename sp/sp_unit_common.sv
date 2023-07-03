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
module sp_unit_common#(
	parameter int RESULT_WIDTH
)
(
	input wire logic clk,
	input wire logic rst,

	input sp_inputs_t sp_inputs,
	unit_issue_interface.unit issue,
	unit_writeback_interface.unit wb,

	input wire logic [SP_UNIT_COMMON_NCMDS-1:0] issue_cmd,
	output wire logic [SP_UNIT_COMMON_NCMDS-1:0] cmds_busy,
	output wire logic [SP_UNIT_COMMON_NCMDS-1:0] cmds_done,
	output var logic [RESULT_WIDTH-1:0] result,

	mmr_readwrite_interface.master mmr_rw,
	mmr_read_interface.master mmr_r,
	mmr_intr_interface.master mmr_i
);

var logic [SP_UNIT_COMMON_NCMDS-1:0] cmds_busy_ff;
var logic [SP_UNIT_COMMON_NCMDS-1:0] cmds_busy_comb;
var logic [SP_UNIT_COMMON_NCMDS-1:0] cmds_done_ff;
var logic [SP_UNIT_COMMON_NCMDS-1:0] cmds_done_comb;
assign cmds_busy = cmds_busy_ff;
assign cmds_done = cmds_done_ff;

/*
 * Command "LOAD REG"
 */
var logic [31:0] load_reg_cur;

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
`ifndef VERILATOR
				if (mmr_r.INDEX_WIDTH == 0)
					load_reg_cur <= mmr_r.data[0];
				else
					load_reg_cur <= mmr_r.data[sp_inputs.rs1[0 +: mmr_r.INDEX_WIDTH]];
`endif
			end
			else begin
`ifndef VERILATOR
				if (mmr_rw.INDEX_WIDTH == 0)
					load_reg_cur <= mmr_rw.data[0];
				else
					load_reg_cur <= mmr_rw.data[sp_inputs.rs1[0 +: mmr_rw.INDEX_WIDTH]];
`endif
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
`ifndef VERILATOR
			if (mmr_rw.INDEX_WIDTH == 0)
				mmr_rw.store_idx <= 0;
			else
				mmr_rw.store_idx <= sp_inputs.rs1[0 +:mmr_rw.INDEX_WIDTH];
`endif
			mmr_rw.store_data <= sp_inputs.rs2;
		end
	end
end

/*
 * Command "INTR"
 */
always_comb begin
	cmds_done_comb[CMD_INTR] = cmds_done_ff[CMD_INTR];
	cmds_busy_comb[CMD_INTR] = cmds_busy_ff[CMD_INTR];

	if (rst) begin
		cmds_done_comb[CMD_INTR] = 1'b0;
		cmds_busy_comb[CMD_INTR] = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_INTR]) begin
			cmds_done_comb[CMD_INTR] = 1'b1;
			cmds_busy_comb[CMD_INTR] = 1'b1;
		end
		if (cmds_done_ff[CMD_INTR] & wb.ack) begin
			cmds_done_comb[CMD_INTR] = 1'b0;
			cmds_busy_comb[CMD_INTR] = 1'b0;
		end
	end
end

always_ff @(posedge clk) begin
	cmds_done_ff[CMD_INTR] <= cmds_done_comb[CMD_INTR];
	cmds_busy_ff[CMD_INTR] <= cmds_busy_comb[CMD_INTR];

	if (rst) begin
		for (int i = 0; i < mmr_i.N; i++)
			mmr_i.isr_pulses[i] <= '0;
	end
	else begin
		// Unpulse
		for (int i = 0; i < mmr_i.N; i++) begin
			mmr_i.isr_pulses[i] <= '0;
		end

		if (issue.new_request & issue.ready & issue_cmd[CMD_INTR]) begin
			mmr_i.isr_pulses[sp_inputs.rs1[$clog2(mmr_i.N)-1:0]] <= sp_inputs.rs2;
		end
	end
end

var logic [SP_UNIT_COMMON_NCMDS-1:0] cur_cmd;

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
	cur_cmd[CMD_LOAD_REG]: result = load_reg_cur;
	endcase
end

endmodule
