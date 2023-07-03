/*
 * Modifications:
 * Copyright (c) 2021-2023 Robert Drehmel
 *
 * Initial implementation:
 * Copyright © 2017-2019 Eric Matthews,  Lesley Shannon
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

module load_store_unit (
	input logic clk,
	input logic rst,
	input load_store_inputs_t ls_inputs,
	unit_issue_interface.unit issue,

	input logic dcache_on,
	input logic clear_reservation,
	tlb_interface.mem tlb,

	input logic gc_fetch_flush,
	input logic gc_issue_flush,

	l1_arbiter_request_interface.master l1_request,
	l1_arbiter_return_interface.master l1_response,
	input sc_complete,
	input sc_success,

	// For the AXI sub unit
	input wire logic [3:0] io_axi_axcache,
	axi_interface.master m_axi,

	// For the scratch memory sub unit
	local_memory_interface.master data_bram,
	// For the acp memory sub unit
	local_memory_interface.master acp_bram,

	//ID Management
	output logic store_complete,
	output id_t store_id,

	//Writeback-Store Interface
	writeback_store_interface.ls wb_store,

	//CSR support
	input logic [31:0] csr_rd,
	input id_t csr_id,
	input logic csr_done,
	output logic ls_is_idle,

	output exception_packet_t ls_exception,
	output logic ls_exception_is_store,

	unit_writeback_interface.unit wb
);

	localparam int NUM_SUB_UNITS = USE_D_SCRATCH_RAM + USE_ACP_RAM + USE_BUS + USE_DCACHE;
	localparam int NUM_SUB_UNITS_W = (NUM_SUB_UNITS == 1) ? 1 : $clog2(NUM_SUB_UNITS);

	localparam int D_SCRATCH_RAM_ID = 0;
	localparam int ACP_RAM_ID = D_SCRATCH_RAM_ID + USE_D_SCRATCH_RAM;
	localparam int BUS_ID = ACP_RAM_ID + USE_ACP_RAM;
	localparam int DCACHE_ID = BUS_ID + USE_BUS;

	//Should be equal to pipeline depth of longest load/store subunit 
	localparam int ATTRIBUTES_DEPTH = USE_DCACHE ? 2 : 1;

	data_access_shared_inputs_t shared_inputs;
	/* See the comment in interfaces.sv for information on
	 * why Verilator needs special handling here.
	 */
	ls_sub_unit_interface #(
`ifndef VERILATOR
		.BASE_ADDR('{SCRATCH_RAM_ADDR_L}),
		.UPPER_BOUND('{SCRATCH_RAM_ADDR_H}),
		.BIT_CHECK('{SCRATCH_RAM_BIT_CHECK})
`else
		.BASE_ADDR_0(SCRATCH_RAM_ADDR_L),
		.UPPER_BOUND_0(SCRATCH_RAM_ADDR_H),
		.BIT_CHECK_0(SCRATCH_RAM_BIT_CHECK)
`endif
	) bram();
	ls_sub_unit_interface #(
`ifndef VERILATOR
		.BASE_ADDR('{ACP_RAM_ADDR_L}),
		.UPPER_BOUND('{ACP_RAM_ADDR_H}),
		.BIT_CHECK('{ACP_RAM_BIT_CHECK})
`else
		.BASE_ADDR_0(ACP_RAM_ADDR_L),
		.UPPER_BOUND_0(ACP_RAM_ADDR_H),
		.BIT_CHECK_0(ACP_RAM_BIT_CHECK)
`endif
	) acpram();
	ls_sub_unit_interface #(
		.N(1),
		.REVERSE(1),
`ifndef VERILATOR
		//.BASE_ADDR('{BUS0_ADDR_L,BUS1_ADDR_L}),
		//.UPPER_BOUND('{BUS0_ADDR_H,BUS1_ADDR_H}),
		//.BIT_CHECK('{BUS0_BIT_CHECK,BUS1_BIT_CHECK})
		.BASE_ADDR('{BUS0_ADDR_L}),
		.UPPER_BOUND('{BUS0_ADDR_H}),
		.BIT_CHECK('{BUS0_BIT_CHECK})
`else
		.BASE_ADDR_0(BUS0_ADDR_L),
		.UPPER_BOUND_0(BUS0_ADDR_H),
		.BIT_CHECK_0(BUS0_BIT_CHECK)
`endif
	) bus();
	ls_sub_unit_interface #(
`ifndef VERILATOR
		.BASE_ADDR('{MEMORY_ADDR_L}),
		.UPPER_BOUND('{MEMORY_ADDR_H}),
		.BIT_CHECK('{MEMORY_BIT_CHECK})
`else
		.BASE_ADDR_0(MEMORY_ADDR_L),
		.UPPER_BOUND_0(MEMORY_ADDR_H),
		.BIT_CHECK_0(MEMORY_BIT_CHECK)
`endif
	) cache();

	logic units_ready;
	logic unit_switch_stall;
	logic ready_for_issue;
	logic issue_request;
	logic load_complete;

	logic [31:0] virtual_address;
	logic [31:0] unit_muxed_load_data;
	logic [31:0] aligned_load_data;
	logic [31:0] final_load_data;

	logic [31:0] unit_data_array [NUM_SUB_UNITS-1:0];
	logic [NUM_SUB_UNITS-1:0] unit_ready;
	logic [NUM_SUB_UNITS-1:0] unit_data_valid;
	logic [NUM_SUB_UNITS-1:0] last_unit;
	logic [NUM_SUB_UNITS-1:0] current_unit;

	logic unaligned_addr;
	logic [NUM_SUB_UNITS-1:0] sub_unit_address_match;

	logic unit_stall;

	typedef struct packed{
		logic [2:0] fn3;
		logic [1:0] byte_addr;
		id_t id;
		logic [NUM_SUB_UNITS_W-1:0] subunit_id;
	} load_attributes_t;
	load_attributes_t load_attributes_in, stage2_attr;

	logic [3:0] be;
	//FIFOs
	fifo_interface #(.DATA_WIDTH($bits(load_attributes_t))) load_attributes();

	load_store_queue_interface lsq();

	logic [31:0] compare_addr;
	logic address_conflict;
	logic ready_for_forwarded_store;
	////////////////////////////////////////////////////
	//Implementation
	////////////////////////////////////////////////////


	////////////////////////////////////////////////////
	//Alignment Exception
generate if (ENABLE_M_MODE) begin
	always_comb begin
		case(ls_inputs.fn3)
		LS_H_fn3: unaligned_addr = virtual_address[0];
		L_HU_fn3: unaligned_addr = virtual_address[0];
		LS_W_fn3: unaligned_addr = |virtual_address[1:0];
		default: unaligned_addr = 0;
		endcase
	end
	assign ls_exception_is_store = ls_inputs.store;
	assign ls_exception.valid = unaligned_addr & issue.new_request;
	assign ls_exception.code = ls_inputs.store ? STORE_AMO_ADDR_MISSALIGNED : LOAD_ADDR_MISSALIGNED;
	assign ls_exception.tval = virtual_address;
	assign ls_exception.id = issue.id;
end
endgenerate
	////////////////////////////////////////////////////
	//TLB interface
	assign virtual_address = ls_inputs.rs1 + 32'(signed'(ls_inputs.offset));

	assign tlb.virtual_address = virtual_address;
	assign tlb.new_request = issue_request;
	assign tlb.execute = 0;
	assign tlb.rnw = ls_inputs.load & ~ls_inputs.store;

	////////////////////////////////////////////////////
	//Byte enable generation
	//Only set on store
	//  SW: all bytes
	//  SH: upper or lower half of bytes
	//  SB: specific byte
	always_comb begin
		be = 0;
		case (ls_inputs.fn3[1:0])
			LS_B_fn3[1:0]: be[virtual_address[1:0]] = 1;
			LS_H_fn3[1:0]: begin
				be[virtual_address[1:0]] = 1;
				be[{virtual_address[1], 1'b1}] = 1;
			end
			default: be = '1;
		endcase
		be &= {4{~ls_inputs.load}};
	end

	////////////////////////////////////////////////////
	//Load Store Queue
	assign lsq.addr = virtual_address;
	assign lsq.fn3 = ls_inputs.fn3;
	assign lsq.be = be;
	assign lsq.data_in = ls_inputs.rs2;
	assign lsq.load = ls_inputs.load;
	assign lsq.lr = ls_inputs.amo.is_lr;
	assign lsq.store = ls_inputs.store;
	assign lsq.sc = ls_inputs.amo.is_sc;
	assign lsq.id = issue.id;
	assign lsq.forwarded_store = ls_inputs.forwarded_store;
	assign lsq.data_id = ls_inputs.store_forward_id;
	assign lsq.possible_issue = issue.possible_issue;
	assign lsq.new_issue = issue.new_request & ~unaligned_addr;
	assign lsq.accepted = issue_request;

	logic [MAX_IDS-1:0] wb_hold_for_store_ids;
	load_store_queue lsq_block (.*);
	assign shared_inputs = lsq.transaction_out;

	////////////////////////////////////////////////////
	//ID Management
	assign store_complete = lsq.accepted & lsq.transaction_out.store & ~lsq.transaction_out.sc;
	assign store_id = lsq.transaction_out.id;

	////////////////////////////////////////////////////
	//Unit tracking
	assign current_unit = sub_unit_address_match;

	initial last_unit = D_SCRATCH_RAM_ID;
	always_ff @ (posedge clk) begin
		if (load_attributes.push)
			last_unit <= sub_unit_address_match;
	end

	//When switching units, ensure no outstanding loads so that there can be no timing collisions with results
	assign unit_stall = (current_unit != last_unit) && load_attributes.valid;
	set_clr_reg_with_rst #(.SET_OVER_CLR(1), .WIDTH(1), .RST_VALUE(0)) unit_switch_stall_m (
	  .clk, .rst,
	  .set(issue_request && (current_unit != last_unit) && load_attributes.valid),
	  .clr(~load_attributes.valid),
	  .result(unit_switch_stall)
	);

	////////////////////////////////////////////////////
	//Primary Control Signals
	assign ls_is_idle = lsq.empty & (~load_attributes.valid);

	assign units_ready = &unit_ready;
	assign load_complete = |unit_data_valid;

	assign ready_for_issue = units_ready & (~unit_switch_stall);

	assign issue.ready = ls_inputs.forwarded_store ? lsq.ready & ready_for_forwarded_store : lsq.ready;
	assign issue_request = lsq.transaction_ready & ready_for_issue;

	////////////////////////////////////////////////////
	//Load attributes FIFO
	one_hot_to_integer #(NUM_SUB_UNITS) sub_unit_select (.*, .one_hot(sub_unit_address_match), .int_out(load_attributes_in.subunit_id));
	taiga_fifo #(.DATA_WIDTH($bits(load_attributes_t)), .FIFO_DEPTH(ATTRIBUTES_DEPTH)) attributes_fifo (.fifo(load_attributes), .*);
	assign load_attributes_in.fn3 = shared_inputs.fn3;
	assign load_attributes_in.byte_addr = shared_inputs.addr[1:0];
	assign load_attributes_in.id = shared_inputs.id;

	assign load_attributes.data_in = load_attributes_in;
	assign load_attributes.push = issue_request & (shared_inputs.load | (shared_inputs.store & shared_inputs.sc));
	assign load_attributes.potential_push = load_attributes.push;
	assign load_attributes.pop = load_complete;

	assign stage2_attr = load_attributes.data_out;

	////////////////////////////////////////////////////
	//Unit Instantiation
	generate if (USE_D_SCRATCH_RAM) begin
		assign sub_unit_address_match[D_SCRATCH_RAM_ID] = bram.address_range_check(shared_inputs.addr);
		assign bram.new_request = sub_unit_address_match[D_SCRATCH_RAM_ID] & issue_request;

		assign unit_ready[D_SCRATCH_RAM_ID] = bram.ready;
		assign unit_data_valid[D_SCRATCH_RAM_ID] = bram.data_valid;

		dbram d_bram(
			.*,
			.ls_inputs(shared_inputs),
			.ls(bram),
			.data_out(unit_data_array[D_SCRATCH_RAM_ID])
		);
	end endgenerate

	generate if (USE_ACP_RAM) begin
		assign sub_unit_address_match[ACP_RAM_ID] = acpram.address_range_check(shared_inputs.addr);
		assign acpram.new_request = sub_unit_address_match[ACP_RAM_ID] & issue_request;

		assign unit_ready[ACP_RAM_ID] = acpram.ready;
		assign unit_data_valid[ACP_RAM_ID] = acpram.data_valid;

		dbram acp_d_bram (
			.*,
			.data_bram(acp_bram),
			.ls_inputs(shared_inputs),
			.ls(acpram),
			.data_out(unit_data_array[ACP_RAM_ID])
		);
	end endgenerate

	generate if (USE_BUS) begin
		assign sub_unit_address_match[BUS_ID] = bus.address_range_check(shared_inputs.addr);
		assign bus.new_request = sub_unit_address_match[BUS_ID] & issue_request;

		assign unit_ready[BUS_ID] = bus.ready;
		assign unit_data_valid[BUS_ID] = bus.data_valid;

		axi_master axi_bus(
			.*,
			.ls_inputs(shared_inputs),
			.size({1'b0,shared_inputs.fn3[1:0]}),
			.io_axi_axcache,
			.m_axi(m_axi),
			.ls(bus),
			.data_out(unit_data_array[BUS_ID])
		); //Lower two bits of fn3 match AXI specification for request size (byte/halfword/word)
	end endgenerate

	generate if (USE_DCACHE) begin
		assign sub_unit_address_match[DCACHE_ID] = cache.address_range_check(shared_inputs.addr);
		assign cache.new_request = sub_unit_address_match[DCACHE_ID] & issue_request;

		assign unit_ready[DCACHE_ID] = cache.ready;
		assign unit_data_valid[DCACHE_ID] = cache.data_valid;

		dcache data_cache(
			.*,
			.ls_inputs(shared_inputs),
			.ls(cache),
			.amo(ls_inputs.amo),
			.data_out(unit_data_array[DCACHE_ID])
		);
	end endgenerate

	////////////////////////////////////////////////////
	//Output Muxing
	assign unit_muxed_load_data = unit_data_array[stage2_attr.subunit_id];

	//Byte/halfword select: assumes aligned operations
	always_comb begin
		aligned_load_data[31:16] = unit_muxed_load_data[31:16];
		aligned_load_data[15:0] = stage2_attr.byte_addr[1] ? unit_muxed_load_data[31:16] : unit_muxed_load_data[15:0];
		//select halfword first then byte
		aligned_load_data[7:0] = stage2_attr.byte_addr[0] ? aligned_load_data[15:8] : aligned_load_data[7:0];
	end

	//Sign extending
	always_comb begin
		case (stage2_attr.fn3)
			LS_B_fn3: final_load_data = 32'(signed'(aligned_load_data[7:0]));
			LS_H_fn3: final_load_data = 32'(signed'(aligned_load_data[15:0]));
			LS_W_fn3: final_load_data = aligned_load_data;
				//unused 011
			L_BU_fn3: final_load_data = 32'(unsigned'(aligned_load_data[7:0]));
			L_HU_fn3: final_load_data = 32'(unsigned'(aligned_load_data[15:0]));
				//unused 110
				//unused 111
			default: final_load_data = aligned_load_data;
		endcase
	end

	////////////////////////////////////////////////////
	//Output bank
	assign wb.rd = csr_done ? csr_rd : final_load_data;
	assign wb.done = csr_done | load_complete;
	assign wb.id = csr_done ? csr_id : stage2_attr.id;

	////////////////////////////////////////////////////
	//End of Implementation
	////////////////////////////////////////////////////

	////////////////////////////////////////////////////
	//Assertions
	spurious_load_complete_assertion:
		assert property (@(posedge clk) disable iff (rst) load_complete |-> (load_attributes.valid && unit_data_valid[stage2_attr.subunit_id]))
		else $error("Spurious load complete detected!");

	csr_load_conflict_assertion:
		assert property (@(posedge clk) disable iff (rst) csr_done |-> ls_is_idle)
		else $error("CSR read completed without ls being idle");

	`ifdef ENABLE_SIMULATION_ASSERTIONS
		invalid_ls_address_assertion:
			assert property (@(posedge clk) disable iff (rst) issue_request |-> |sub_unit_address_match)
			else $error("invalid L/S address");
	`endif

endmodule
