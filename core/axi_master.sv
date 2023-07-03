/*
 * Modifications:
 * Copyright (c) 2021-2023 Robert Drehmel
 *
 * Initial implementation:
 * Copyright © 2017 Eric Matthews,  Lesley Shannon
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Initial code developed under the supervision of Dr. Lesley Shannon,
 * Reconfigurable Computing Lab, Simon Fraser University.
 *
 * Author(s):
 *             Eric Matthews <ematthew@sfu.ca>
 */

import taiga_config::*;
import riscv_types::*;
import taiga_types::*;

module axi_master (
	input logic clk,
	input logic rst,

	input logic [3:0] io_axi_axcache,
	axi_interface.master m_axi,
	input logic [2:0] size,
	output logic [31:0] data_out,

	input data_access_shared_inputs_t ls_inputs,
	ls_sub_unit_interface.sub_unit ls
);
logic ready;

//read constants
assign m_axi.arlen = 0; // 1 request
/* Burst type should not matter as ARLEN is set to zero.
 * However, make sure to use an ARBURST type of INCR (instead
 * of FIXED), because the Xilinx AXI Smartconnect (that is now
 * recommended over AXI Interconnect for most use-cases) returns
 * a DECERR on the B channel in the case of ARBURST=FIXED.
 */
assign m_axi.arburst = 2'b01;
assign m_axi.rready = 1; //always ready to receive data

wire logic is_cached_access;
wire logic [3:0] axcache;

/*
 * Wow! If axcache is 4'b0011, we get an AXI DECERR error in the B channel
 * when trying to write to 0xfd6e4000.
 * It seems to work perfectly when using 4'b0000 with a smartconnect converting
 * our SP AXI 32-bit bus to the 128 bits of the HPC0.
 * is_cached_access will be set only if the address starts with 0x2xxxxxxx and
 * neither AxLOCK bits are requested.
 */
assign is_cached_access = (ls_inputs.addr[31:28] == 4'b0010) & ~(ls_inputs.lr | ls_inputs.sc);
assign axcache = is_cached_access ? io_axi_axcache : 4'b0000;

always_ff @ (posedge clk) begin
	if (ls.new_request) begin
		m_axi.araddr <= ls_inputs.addr;
		m_axi.arsize <= size;
		m_axi.arlock <= ls_inputs.lr;
		m_axi.arcache <= axcache;
		m_axi.arprot <= 3'b010;

		m_axi.awaddr <= ls_inputs.addr;
		m_axi.awsize <= size;
		m_axi.awlock <= ls_inputs.sc;
		m_axi.awcache <= axcache;
		m_axi.awprot <= 3'b010;
		m_axi.wdata <= ls_inputs.data_in;
		m_axi.wstrb <= { {($bits(m_axi.wdata) - 32) / 8{1'b0}}, ls_inputs.be };
	end
end

//write constants
assign m_axi.awlen = 0;
// Refer to the comment for ARBURST above that explains why
// we used AWBURST=INCR here.
assign m_axi.awburst = 2'b01;
assign m_axi.bready = 1;

set_clr_reg_with_rst #(.SET_OVER_CLR(0), .WIDTH(1), .RST_VALUE(1)) ready_m (
	.clk, .rst,
	.set(m_axi.rvalid | m_axi.bvalid),
	.clr(ls.new_request),
	.result(ready)
);
assign ls.ready = ready;

always_ff @ (posedge clk) begin
	if (rst)
		ls.data_valid <= 0;
	else
		ls.data_valid <= m_axi.rvalid | (m_axi.bvalid & m_axi.awlock);
end

//read channel
set_clr_reg_with_rst #(.SET_OVER_CLR(1), .WIDTH(1), .RST_VALUE(0)) arvalid_m (
	.clk, .rst,
	.set(ls.new_request & ls_inputs.load),
	.clr(m_axi.arready),
	.result(m_axi.arvalid)
);

always_ff @ (posedge clk) begin
	if (m_axi.rvalid) begin
		// We use the [31:0] slice here because .rdata might have a width of >32 bits.
		// --robert
		data_out <= m_axi.rdata[31:0];
	end
	if (m_axi.bvalid & m_axi.awlock) begin
		// The 2'b01 here is EXOKAY
		data_out <= { 31'b0, m_axi.bresp == 2'b01 ? 1'b0 : 1'b1 };
	end
end

//write channel
set_clr_reg_with_rst #(.SET_OVER_CLR(1), .WIDTH(1), .RST_VALUE(0)) awvalid_m (
	.clk, .rst,
	.set(ls.new_request & ls_inputs.store),
	.clr(m_axi.awready),
	.result(m_axi.awvalid)
);

set_clr_reg_with_rst #(.SET_OVER_CLR(1), .WIDTH(1), .RST_VALUE(0)) wvalid_m (
	.clk, .rst,
	.set(ls.new_request & ls_inputs.store),
	.clr(m_axi.wready),
	.result(m_axi.wvalid)
);
assign m_axi.wlast = m_axi.wvalid;

endmodule
