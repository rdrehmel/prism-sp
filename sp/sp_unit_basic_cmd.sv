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
module sp_unit_basic_cmd
(
	input wire logic clk,
	input wire logic rst,
	unit_issue_interface.unit issue,
	unit_writeback_interface.unit wb,
	input wire logic issue_cmd,
	output wire logic cmd_busy,
	output wire logic cmd_done
);

var logic cmd_busy_and_done_ff;
var logic cmd_busy_and_done_comb;

assign cmd_busy = cmd_busy_and_done_ff;
assign cmd_done = cmd_busy_and_done_ff;

always_ff @(posedge clk) begin
	cmd_busy_and_done_ff <= cmd_busy_and_done_comb;
end

always_comb begin
	cmd_busy_and_done_comb = cmd_busy_and_done_ff;

	if (rst) begin
		cmd_busy_and_done_comb = 1'b0;
	end
	else begin
		if (issue.new_request & issue.ready & issue_cmd) begin
			cmd_busy_and_done_comb = 1'b1;
		end
		if (cmd_busy_and_done_ff & wb.ack) begin
			cmd_busy_and_done_comb = 1'b0;
		end
	end
end

endmodule
