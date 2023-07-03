/*
 * Copyright (c) 2023 Robert Drehmel
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
module sp_unit_acp#(
	parameter int RESULT_WIDTH
)
(
	input wire logic clk,
	input wire logic rst,

	input sp_inputs_t sp_inputs,
	unit_issue_interface.unit issue,
	unit_writeback_interface.unit wb,

	input wire logic [SP_UNIT_ACP_NCMDS-1:0] issue_cmd,
	output wire logic [SP_UNIT_ACP_NCMDS-1:0] cmds_busy,
	output wire logic [SP_UNIT_ACP_NCMDS-1:0] cmds_done,
	output var logic [RESULT_WIDTH-1:0] result,

	xpm_memory_tdpram_port_interface.master acpram_port_i,

	axi_write_address_channel.master m_axi_acp_aw,
	axi_write_channel.master m_axi_acp_w,
	axi_write_response_channel.master m_axi_acp_b,
	axi_read_address_channel.master m_axi_acp_ar,
	axi_read_channel.master m_axi_acp_r
);

/*
 * Interfaces for the ACP memory
 */
acpram_axi_interface #(
	.ACPRAM_ADDR_WIDTH($bits(acpram_port_i.din)),
	.AXI_ADDR_WIDTH(32)
) acpram_axi_i();

/*
 * Command "READ START"
 */
sp_unit_basic_cmd sp_unit_basic_cmd_acp_read_start(
	.clk(clk),
	.rst(rst),
	.issue(issue),
	.wb(wb),
	.issue_cmd(issue_cmd[CMD_ACP_READ_START]),
	.cmd_busy(cmds_busy[CMD_ACP_READ_START]),
	.cmd_done(cmds_done[CMD_ACP_READ_START])
);

always_ff @(posedge clk) begin
	if (rst) begin
	end
	else begin
		// Unpulse
		acpram_axi_i.read <= 1'b0;
		acpram_axi_i.write <= 1'b0;

		if (issue.new_request & issue.ready) begin
			acpram_axi_i.read <= issue_cmd[CMD_ACP_READ_START];
			acpram_axi_i.write <= issue_cmd[CMD_ACP_WRITE_START];

			if (issue_cmd[CMD_ACP_READ_START] || issue_cmd[CMD_ACP_WRITE_START]) begin
				// We want to use byte addresses to avoid violating POLA.
				acpram_axi_i.acpram_addr <= sp_inputs.rs1[31:4];
				acpram_axi_i.axi_addr <= sp_inputs.rs2;
				acpram_axi_i.len <= sp_inputs.fn3[0];
			end
		end
	end
end

/*
 * Command "READ STATUS"
 */
var logic acp_read_status_result_ff;

sp_unit_basic_cmd sp_unit_basic_cmd_acp_read_status(
	.clk(clk),
	.rst(rst),
	.issue(issue),
	.wb(wb),
	.issue_cmd(issue_cmd[CMD_ACP_READ_STATUS]),
	.cmd_done(cmds_done[CMD_ACP_READ_STATUS]),
	.cmd_busy(cmds_busy[CMD_ACP_READ_STATUS])
);

always_ff @(posedge clk) begin
	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_ACP_READ_STATUS]) begin
			acp_read_status_result_ff <= acpram_axi_i.busy;
		end
	end
end

/*
 * Command "WRITE START"
 */
sp_unit_basic_cmd sp_unit_basic_cmd_acp_write_start(
	.clk(clk),
	.rst(rst),
	.issue(issue),
	.wb(wb),
	.issue_cmd(issue_cmd[CMD_ACP_WRITE_START]),
	.cmd_done(cmds_done[CMD_ACP_WRITE_START]),
	.cmd_busy(cmds_busy[CMD_ACP_WRITE_START])
);

// The write start command is handled along with "read start" above.

/*
 * Command "WRITE STATUS"
 */
var logic acp_write_status_result_ff;

sp_unit_basic_cmd sp_unit_basic_cmd_acp_write_status(
	.clk(clk),
	.rst(rst),
	.issue(issue),
	.wb(wb),
	.issue_cmd(issue_cmd[CMD_ACP_WRITE_STATUS]),
	.cmd_done(cmds_done[CMD_ACP_WRITE_STATUS]),
	.cmd_busy(cmds_busy[CMD_ACP_WRITE_STATUS])
);

always_ff @(posedge clk) begin
	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_ACP_WRITE_STATUS]) begin
			acp_write_status_result_ff <= acpram_axi_i.busy;
		end
	end
end

/*
 * Command "Set local write strobes"
 */
// 4x 16 bits of write enable bits for the 1st, 2nd, 3rd, 4th AXI transfer beat.
var logic [15:0] acp_local_wstrb [4];

sp_unit_basic_cmd sp_unit_basic_cmd_acp_set_local_wstrb(
	.clk(clk),
	.rst(rst),
	.issue(issue),
	.wb(wb),
	.issue_cmd(issue_cmd[CMD_ACP_SET_LOCAL_WSTRB]),
	.cmd_done(cmds_done[CMD_ACP_SET_LOCAL_WSTRB]),
	.cmd_busy(cmds_busy[CMD_ACP_SET_LOCAL_WSTRB])
);

always_ff @(posedge clk) begin
	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_ACP_SET_LOCAL_WSTRB]) begin
			acp_local_wstrb[sp_inputs.fn3[1:0]] <= sp_inputs.rs1[15:0];
		end
	end
end

/*
 * Command "Set remote write strobes"
 */
// For a 1-beat transaction, these write enable bits are used.
var logic [15:0] acp_remote_wstrb_0;
/* For a 4-beat transaction, these write enable bits are used.
 * Note that for 4-beat transaction, all enable bits have to
 * have either all bits set or unset.
 */
var logic [3:0] acp_remote_wstrb_0123;

sp_unit_basic_cmd sp_unit_basic_cmd_acp_set_remote_wstrb(
	.clk(clk),
	.rst(rst),
	.issue(issue),
	.wb(wb),
	.issue_cmd(issue_cmd[CMD_ACP_SET_REMOTE_WSTRB]),
	.cmd_done(cmds_done[CMD_ACP_SET_REMOTE_WSTRB]),
	.cmd_busy(cmds_busy[CMD_ACP_SET_REMOTE_WSTRB])
);

always_ff @(posedge clk) begin
	if (rst) begin
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd[CMD_ACP_SET_REMOTE_WSTRB]) begin
			if (sp_inputs.fn3[0]) begin
				acp_remote_wstrb_0123 <= sp_inputs.rs1[3:0];
			end
			else begin
				acp_remote_wstrb_0 <= sp_inputs.rs1[15:0];
			end
		end
	end
end

/*
 * Remember current command
 */
var logic [SP_UNIT_ACP_NCMDS-1:0] cur_cmd;

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
	cur_cmd[CMD_ACP_READ_STATUS]: result[0] = acp_read_status_result_ff;
	cur_cmd[CMD_ACP_WRITE_STATUS]: result[0] = acp_write_status_result_ff;
	endcase
end

acpram_axi acpram_axi_0(
	.clock(clk),
	.resetn(~rst),

	.acp_local_wstrb,
	.acp_remote_wstrb_0,
	.acp_remote_wstrb_0123,

	.acpram_axi_i,
	.acpram_port_i,

	.axi_aw(m_axi_acp_aw),
	.axi_w(m_axi_acp_w),
	.axi_b(m_axi_acp_b),
	.axi_ar(m_axi_acp_ar),
	.axi_r(m_axi_acp_r)
);

endmodule
