/*
 * Copyright (c) 2016-2023 Robert Drehmel
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
//
// FIFO -> AXI[w]
//
module fifo_to_axi
#(
	parameter integer AXI_ADDR_WIDTH = 32
)
(
	input wire logic clock,
	input wire logic reset_n,

	// Interface to start memory writing process
	memory_write_interface.slave mem_w,
	// Interface to read from a FIFO
	fifo_read_interface.master fifo_r,

	// Interface of the actual AXI writing channel(s)
	axi_write_address_channel.master axi_aw,
	axi_write_channel.master axi_w,
	axi_write_response_channel.master axi_b
);

localparam int AXI_DATA_WIDTH = axi_w.AXI_WDATA_WIDTH;
localparam int MAX_NBYTES_PER_BURST = 256 * (AXI_DATA_WIDTH / 8);
localparam int LEN_WIDTH = 16;
localparam int ALIGN_WIDTH = $clog2(AXI_DATA_WIDTH / 8);

assign axi_aw.awid = '0;
// Size should be AXI_DATA_WIDTH, in 2^AWSIZE bytes, otherwise narrow bursts are
// used
localparam int AWSIZE = $clog2((AXI_DATA_WIDTH/8)-1);
assign axi_aw.awsize = AWSIZE[2:0];
// INCR burst type
assign axi_aw.awburst = 2'b01;
assign axi_aw.awlock = 0;
// Not used anymore.
// Was: 
// Not Allocated, Modifiable, not Bufferable.
// assign axi_aw.awcache = 4'b0010;
assign axi_aw.awprot = 3'h0;
assign axi_aw.awqos = 4'h0;
assign axi_aw.awuser = 1;
assign axi_w.wuser = 0;

// ------- ------- ------- ------- ------- ------- ------- -------
//
// AXI SECTION A2.2: Write Address Channel
//
// ------- ------- ------- ------- ------- ------- ------- -------

// Little helpers
wire logic aw_hshake = axi_aw.awvalid && axi_aw.awready;
wire logic w_hshake = axi_w.wvalid && axi_w.wready;
wire logic w_hshake_last = w_hshake && axi_w.wlast;
wire logic w_hshake_not_last = w_hshake && !axi_w.wlast;
wire logic b_hshake = axi_b.bvalid && axi_b.bready;

assign fifo_r.rd_en = write_burst_start || w_hshake_not_last;

var logic [7:0] axi_aw_awlen_comb;
always_comb begin
	if (full_bursts_left != '0) begin
		axi_aw_awlen_comb = 255;
	end
	else begin
		// See the comment in axi_to_fifo.sv for an explanation.
		if (extra_bytes != '0)
			axi_aw_awlen_comb = beats_left;
		else
			axi_aw_awlen_comb = beats_left - 1;
	end
end

always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_aw.awvalid <= 1'b0;
	end
	else begin
		if (write_burst_start) begin
			axi_aw.awvalid <= 1'b1;
			axi_aw.awaddr <= dest_addr;
			axi_aw.awlen <= axi_aw_awlen_comb;
		end
		else if (aw_hshake) begin
			// The address was successfully submitted.
			// Now deassert AWVALID until the next burst starts.
			axi_aw.awvalid <= 1'b0;
		end
	end
end

// ------- ------- ------- ------- ------- ------- ------- -------
//
// AXI SECTION A2.3: Write Data Channel
//
// ------- ------- ------- ------- ------- ------- ------- -------
var logic [(AXI_DATA_WIDTH/8)-1:0] axi_w_wstrb_comb;
/* Switch off verilator's linting because it does not
 * honor the fact that the widths of the RHSs are
 * correct iff the preceding if-clause is true.
 */
/* verilator lint_off WIDTH */
always_comb begin
if (AXI_DATA_WIDTH == 32) begin
	case (extra_bytes)
	2'b00: axi_w_wstrb_comb = 4'b1111;
	2'b01: axi_w_wstrb_comb = 4'b0001;
	2'b10: axi_w_wstrb_comb = 4'b0011;
	2'b11: axi_w_wstrb_comb = 4'b0111;
	endcase
end
else if (AXI_DATA_WIDTH == 64) begin
	case (extra_bytes)
	3'b000: axi_w_wstrb_comb = 8'b11111111;
	3'b001: axi_w_wstrb_comb = 8'b00000001;
	3'b010: axi_w_wstrb_comb = 8'b00000011;
	3'b011: axi_w_wstrb_comb = 8'b00000111;
	3'b100: axi_w_wstrb_comb = 8'b00001111;
	3'b101: axi_w_wstrb_comb = 8'b00011111;
	3'b110: axi_w_wstrb_comb = 8'b00111111;
	3'b111: axi_w_wstrb_comb = 8'b01111111;
	endcase
end
else if (AXI_DATA_WIDTH == 128) begin
	case (extra_bytes)
	4'b0000: axi_w_wstrb_comb = 16'b1111111111111111;
	4'b0001: axi_w_wstrb_comb = 16'b0000000000000001;
	4'b0010: axi_w_wstrb_comb = 16'b0000000000000011;
	4'b0011: axi_w_wstrb_comb = 16'b0000000000000111;
	4'b0100: axi_w_wstrb_comb = 16'b0000000000001111;
	4'b0101: axi_w_wstrb_comb = 16'b0000000000011111;
	4'b0110: axi_w_wstrb_comb = 16'b0000000000111111;
	4'b0111: axi_w_wstrb_comb = 16'b0000000001111111;
	4'b1000: axi_w_wstrb_comb = 16'b0000000011111111;
	4'b1001: axi_w_wstrb_comb = 16'b0000000111111111;
	4'b1010: axi_w_wstrb_comb = 16'b0000001111111111;
	4'b1011: axi_w_wstrb_comb = 16'b0000011111111111;
	4'b1100: axi_w_wstrb_comb = 16'b0000111111111111;
	4'b1101: axi_w_wstrb_comb = 16'b0001111111111111;
	4'b1110: axi_w_wstrb_comb = 16'b0011111111111111;
	4'b1111: axi_w_wstrb_comb = 16'b0111111111111111;
	endcase
end
end
/* verilator lint_on WIDTH */

always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_w.wvalid <= 1'b0;
	end
	else begin
		if (write_burst_start) begin
			axi_w.wvalid <= 1'b1;
			axi_w.wdata <= fifo_r.rd_data;
			if (axi_aw_awlen_comb == '0) begin
				axi_w.wlast <= 1'b1;
				axi_w.wstrb <= axi_w_wstrb_comb;
			end
			else begin
				axi_w.wlast <= 1'b0;
				axi_w.wstrb <= '1;
			end
		end
		else if (w_hshake_not_last) begin
			axi_w.wvalid <= 1'b1;
			axi_w.wdata <= fifo_r.rd_data;
			if (w_hshake_count_comb == axi_aw.awlen) begin
				axi_w.wlast <= 1'b1;
				if (full_bursts_left == '0)
					axi_w.wstrb <= axi_w_wstrb_comb;
				else
					axi_w.wstrb <= '1;
			end
			else begin
				axi_w.wlast <= 1'b0;
				axi_w.wstrb <= '1;
			end
		end
		else if (w_hshake_last) begin
			axi_w.wvalid <= 1'b0;
		end
	end
end

// ------- ------- ------- ------- ------- ------- ------- -------
//
// AXI SECTION A2.4: Write Response (B) Channel
//
// ------- ------- ------- ------- ------- ------- ------- -------
always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_b.bready <= 1'b0;
	end
	else begin
		if (w_hshake_last) begin
			axi_b.bready <= 1'b1;
		end
		else if (b_hshake) begin
			axi_b.bready <= 1'b0;
		end
	end
end

// ------- ------- ------- ------- ------- ------- ------- -------
//
// Write operation FSM helpers
//
// ------- ------- ------- ------- ------- ------- ------- -------
// `w_hshake_count` increments once for each successful (=handshake)
// write transaction during a burst.
var logic [7:0] w_hshake_count_comb;
var logic [7:0] w_hshake_count_ff;

always_comb begin
	w_hshake_count_comb = w_hshake_count_ff;

	if (!reset_n) begin
		w_hshake_count_comb = '0;
	end
	else begin
		if (write_burst_start) begin
			w_hshake_count_comb = '0;
		end
		if (w_hshake) begin
			w_hshake_count_comb = w_hshake_count_ff + 1;
		end
	end
end

always_ff @(posedge clock) begin
	w_hshake_count_ff <= w_hshake_count_comb;
end

var logic write_burst_done;
always_ff @(posedge clock) begin
	if (!reset_n) begin
		write_burst_done <= 1'b0;
	end
	else begin
		// unpulse
		write_burst_done <= 1'b0;

		if (b_hshake) begin
			write_burst_done <= 1'b1;
		end
	end
end

// ------- ------- ------- ------- ------- ------- ------- -------
//
// Write operation main
//
// ------- ------- ------- ------- ------- ------- ------- -------
// Writing initiation pulse
var logic write_burst_start;
var logic [(LEN_WIDTH-8-ALIGN_WIDTH)-1:0] full_bursts_left;
var logic [7:0] beats_left;
var logic [ALIGN_WIDTH-1:0] extra_bytes;
var logic [AXI_ADDR_WIDTH-1:0] dest_addr;

always_ff @(posedge clock) begin
	if (!reset_n) begin
		write_burst_start <= 0;
		mem_w.busy <= 1'b0;
		mem_w.done <= 1'b0;
	end
	else begin
		// Unpulse
		write_burst_start <= 1'b0;
		mem_w.done <= 1'b0;

		if (mem_w.busy == 1'b0 && mem_w.start) begin
			$display("mem_w.start pulse: .addr=%x .len=%d",
				mem_w.addr, mem_w.len);

			if (mem_w.len == 0) begin
				mem_w.error <= 1;
				mem_w.done <= 1'b1;
			end
			else begin
				dest_addr <= mem_w.addr;
				full_bursts_left <= mem_w.len[LEN_WIDTH-1:8+ALIGN_WIDTH];
				beats_left <= mem_w.len[8+ALIGN_WIDTH-1:ALIGN_WIDTH];
				extra_bytes <= mem_w.len[ALIGN_WIDTH-1:0];
				mem_w.busy <= 1'b1;
				write_burst_start <= 1'b1;
			end
		end

		if (mem_w.busy == 1'b1 && write_burst_done) begin
			$display("write_burst_done pulse");

			if (full_bursts_left > 1 ||
				(full_bursts_left == 1 && |{beats_left,extra_bytes}))
			begin
				dest_addr <= dest_addr + MAX_NBYTES_PER_BURST[AXI_ADDR_WIDTH-1:0];
				full_bursts_left <= full_bursts_left - 1;
				write_burst_start <= 1'b1;
			end
			else begin
				mem_w.error <= 1'b0;
				mem_w.done <= 1'b1;
				mem_w.busy <= 1'b0;
			end
		end
	end
end

endmodule
