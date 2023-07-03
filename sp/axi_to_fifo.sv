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
// AXI[r] -> FIFO
module axi_to_fifo #
(
	parameter integer AXI_ADDR_WIDTH = 32
)
(
	input wire logic clock,
	input wire logic reset_n,

	// Interface to start the memory reading process
	memory_read_interface.slave mem_r,
	// Interface to write to a FIFO
	fifo_write_interface.master fifo_w,

	// Actual AXI memory interface for reading
	axi_read_address_channel.master axi_ar,
	axi_read_channel.master axi_r
);

localparam int AXI_DATA_WIDTH = axi_r.AXI_RDATA_WIDTH;
localparam int MAX_NBYTES_PER_BURST = 256 * (AXI_DATA_WIDTH / 8);
localparam int LEN_WIDTH = 16;
localparam int ALIGN_WIDTH = $clog2(AXI_DATA_WIDTH / 8);

//
// Set up the FIFO Write interface
//
wire logic ar_hshake = axi_ar.arvalid && axi_ar.arready;
wire logic r_hshake = axi_r.rvalid && axi_r.rready;
wire logic r_hshake_last = r_hshake && axi_r.rlast;

//
// Set up the AXI Read Channel interface
//
// Read Address
assign axi_ar.arid = '0;
// ARSIZE(exponent to 2^n bytes) is derived from AXI_DATA_WIDTH
// axi_ar.arsize is in bytes.
localparam int ARSIZE = $clog2((AXI_DATA_WIDTH/8)-1);
assign axi_ar.arsize = ARSIZE[2:0];
// INCR burst type
assign axi_ar.arburst = 2'b01;
assign axi_ar.arlock = 1'b0;
// This is now set by the user of the module.
// Was:
// Not Allocated, Modifiable, not Bufferable.
// assign axi_ar.arcache = 4'b0010;
assign axi_ar.arprot = 3'h0;
assign axi_ar.arqos = 4'h0;
assign axi_ar.aruser = '1;

// ------- ------- ------- ------- ------- ------- ------- -------
//
// AXI SECTION A2.5: Read Address Channel
//
// ------- ------- ------- ------- ------- ------- ------- -------
// slave asserts RVALID and keeps it asserted.
// When master is ready to accept data, master asserts RREADY
// On the next clock posedge where both RVALID(S) and RREADY(M)
// are asserted, the data in RDATA is transferred.
//
always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_ar.arvalid <= 1'b0;
	end
	else begin
		if (read_burst_start) begin
			axi_ar.arvalid <= 1'b1;
			axi_ar.araddr <= src_addr;

			// Example for a 32-bit data width:
			//
			// 16       8       0
			//  |-------|-------|
			//   YYYYYYXXXXXXXXAA
			//      YYY is the number of full bursts
			// XXXXXXXX is the number of beats
			//       AA is the number of extra bytes
			//
			// So this "if" condition below is just whether a Y bit is
			// set.
			if (full_bursts_left != '0) begin
				axi_ar.arlen <= 255;
			end
			else begin
				// If it isn't, round up if necessary (effectively adding
				// 1 to XXXXXXXX and then subtracting 1).
				// Otherwise, just subtract 1. There is no need to
				// use bytes_left[ALIGN +:9] in this case, because
				// that would only be necessary if there are bits set
				// in bytes_left above bit (8+ALIGN-1) which cannot
				// happen because these are the YYY bits so we would not
				// end up here in the first place.
				if (extra_bytes != '0)
					axi_ar.arlen <= beats_left;
				else
					axi_ar.arlen <= beats_left - 1;
			end
			// Prepare these values here.
			rlast_lt_full <= last_write_bytes[ALIGN_WIDTH] == 1'b0;
			rlast_gt_full <= last_write_bytes[ALIGN_WIDTH] == 1'b1 &&
				|last_write_bytes[ALIGN_WIDTH-1:0] != 1'b0;
		end
		else if (ar_hshake) begin
			axi_ar.arvalid <= 1'b0;
		end
	end
end

// ------- ------- ------- ------- ------- ------- ------- -------
//
// AXI SECTION A2.6: Read Data (and Response) Channel
//
// ------- ------- ------- ------- ------- ------- ------- -------

always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_r.rready <= 1'b0;
	end
	else begin
		if (ar_hshake) begin
			axi_r.rready <= 1'b1;
		end
		else if (r_hshake_last) begin
			axi_r.rready <= 1'b0;
		end
	end
end

// ------- ------- ------- ------- ------- ------- ------- -------
//
// Read operation FSM helpers
//
// ------- ------- ------- ------- ------- ------- ------- -------

var logic read_burst_done;
always_ff @(posedge clock) begin
	if (!reset_n) begin
		read_burst_done <= 1'b0;
	end
	else begin
		// Unpulse
		read_burst_done <= 1'b0;

		if (r_hshake_last) begin
			read_burst_done <= 1'b1;
		end
	end
end

var logic [$bits(axi_r.rdata)-1:0] reordered_axi_rdata_comb;
var logic [$bits(axi_r.rdata)-1:0] last_axi_rdata_comb;
var logic [$bits(axi_r.rdata)-1:0] last_axi_rdata_ff;
var logic [ALIGN_WIDTH-1:0] current_offset;

if (AXI_DATA_WIDTH == 32) begin
always_comb begin
	case (current_offset)
	2'b00: begin
		reordered_axi_rdata_comb = axi_r.rdata;
		last_axi_rdata_comb = '0;
	end
	2'b01: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:3*8], last_axi_rdata_ff[0 +:1*8] };
		last_axi_rdata_comb = { {3*8{1'b0}}, axi_r.rdata[3*8 +:1*8] };
	end
	2'b10: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:2*8], last_axi_rdata_ff[0 +:2*8] };
		last_axi_rdata_comb = { {2*8{1'b0}}, axi_r.rdata[2*8 +:2*8] };
	end
	2'b11: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:1*8], last_axi_rdata_ff[0 +:3*8] };
		last_axi_rdata_comb = { {1*8{1'b0}}, axi_r.rdata[1*8 +:3*8] };
	end
	endcase
end
end
else if (AXI_DATA_WIDTH == 64) begin
always_comb begin
	case (current_offset)
	3'b000: begin
		reordered_axi_rdata_comb = axi_r.rdata;
		last_axi_rdata_comb = '0;
	end
	3'b001: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:7*8], last_axi_rdata_ff[0 +:1*8] };
		last_axi_rdata_comb = { {7*8{1'b0}}, axi_r.rdata[7*8 +:1*8] };
	end
	3'b010: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:6*8], last_axi_rdata_ff[0 +:2*8] };
		last_axi_rdata_comb = { {6*8{1'b0}}, axi_r.rdata[6*8 +:2*8] };
	end
	3'b011: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:5*8], last_axi_rdata_ff[0 +:3*8] };
		last_axi_rdata_comb = { {5*8{1'b0}}, axi_r.rdata[5*8 +:3*8] };
	end
	3'b100: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:4*8], last_axi_rdata_ff[0 +:4*8] };
		last_axi_rdata_comb = { {4*8{1'b0}}, axi_r.rdata[4*8 +:4*8] };
	end
	3'b101: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:3*8], last_axi_rdata_ff[0 +:5*8] };
		last_axi_rdata_comb = { {3*8{1'b0}}, axi_r.rdata[3*8 +:5*8] };
	end
	3'b110: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:2*8], last_axi_rdata_ff[0 +:6*8] };
		last_axi_rdata_comb = { {2*8{1'b0}}, axi_r.rdata[2*8 +:6*8] };
	end
	3'b111: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:1*8], last_axi_rdata_ff[0 +:7*8] };
		last_axi_rdata_comb = { {1*8{1'b0}}, axi_r.rdata[1*8 +:7*8] };
	end
	endcase
end
end
else if (AXI_DATA_WIDTH == 128) begin
always_comb begin
	case (current_offset)
	4'b0000: begin
		reordered_axi_rdata_comb = axi_r.rdata;
		last_axi_rdata_comb = '0;
	end
	4'b0001: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:15*8], last_axi_rdata_ff[0 +:1*8] };
		last_axi_rdata_comb = { {15*8{1'b0}}, axi_r.rdata[15*8 +:1*8] };
	end
	4'b0010: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:14*8], last_axi_rdata_ff[0 +:2*8] };
		last_axi_rdata_comb = { {14*8{1'b0}}, axi_r.rdata[14*8 +:2*8] };
	end
	4'b0011: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:13*8], last_axi_rdata_ff[0 +:3*8] };
		last_axi_rdata_comb = { {13*8{1'b0}}, axi_r.rdata[13*8 +:3*8] };
	end
	4'b0100: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:12*8], last_axi_rdata_ff[0 +:4*8] };
		last_axi_rdata_comb = { {12*8{1'b0}}, axi_r.rdata[12*8 +:4*8] };
	end
	4'b0101: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:11*8], last_axi_rdata_ff[0 +:5*8] };
		last_axi_rdata_comb = { {11*8{1'b0}}, axi_r.rdata[11*8 +:5*8] };
	end
	4'b0110: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:10*8], last_axi_rdata_ff[0 +:6*8] };
		last_axi_rdata_comb = { {10*8{1'b0}}, axi_r.rdata[10*8 +:6*8] };
	end
	4'b0111: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:9*8], last_axi_rdata_ff[0 +:7*8] };
		last_axi_rdata_comb = { {9*8{1'b0}}, axi_r.rdata[9*8 +:7*8] };
	end
	4'b1000: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:8*8], last_axi_rdata_ff[0 +:8*8] };
		last_axi_rdata_comb = { {8*8{1'b0}}, axi_r.rdata[8*8 +:8*8] };
	end
	4'b1001: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:7*8], last_axi_rdata_ff[0 +:9*8] };
		last_axi_rdata_comb = { {7*8{1'b0}}, axi_r.rdata[7*8 +:9*8] };
	end
	4'b1010: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:6*8], last_axi_rdata_ff[0 +:10*8] };
		last_axi_rdata_comb = { {6*8{1'b0}}, axi_r.rdata[6*8 +:10*8] };
	end
	4'b1011: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:5*8], last_axi_rdata_ff[0 +:11*8] };
		last_axi_rdata_comb = { {5*8{1'b0}}, axi_r.rdata[5*8 +:11*8] };
	end
	4'b1100: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:4*8], last_axi_rdata_ff[0 +:12*8] };
		last_axi_rdata_comb = { {4*8{1'b0}}, axi_r.rdata[4*8 +:12*8] };
	end
	4'b1101: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:3*8], last_axi_rdata_ff[0 +:13*8] };
		last_axi_rdata_comb = { {3*8{1'b0}}, axi_r.rdata[3*8 +:13*8] };
	end
	4'b1110: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:2*8], last_axi_rdata_ff[0 +:14*8] };
		last_axi_rdata_comb = { {2*8{1'b0}}, axi_r.rdata[2*8 +:14*8] };
	end
	4'b1111: begin
		reordered_axi_rdata_comb = { axi_r.rdata[0 +:1*8], last_axi_rdata_ff[0 +:15*8] };
		last_axi_rdata_comb = { {1*8{1'b0}}, axi_r.rdata[1*8 +:15*8] };
	end
	endcase
end
end

var logic rlast_lt_full;
var logic rlast_gt_full;
// We keep this around to be able to detect the cycle just after the
// last read beat.
var logic extra_write;
always_ff @(posedge clock) begin
	if (!reset_n) begin
		fifo_w.wr_en <= 1'b0;
		extra_write <= 1'b0;
	end
	else begin
		// Unpulse
		fifo_w.wr_en <= 1'b0;
		extra_write <= 1'b0;

		if (r_hshake) begin
			/* 
			 * There are three cases to handle here.
			 * 1) a less-than-full data word to write
			 *   o) If 'cont' is set, don't write non-full data words to the FIFO.
			 *   x) If 'cont' is not set, write the non-full data word to the FIFO.
			 * 2) a full data word to write
			 *   o) Whether or not cont is set, write the full data word to the FIFO.
			 * 3) more than a full data word to write
			 *   o) Whether or not cont is set, write the full data word to the FIFO
			 *		and store the extra bytes.
			 *   x) If 'cont' is not set, set 'extra_write' to write the remaining bytes
			 *		in the next cycle.
			 */
			if (axi_r.rlast & rlast_lt_full & cont) begin
				last_axi_rdata_ff <= reordered_axi_rdata_comb;
			end
			else begin
				fifo_w.wr_en <= 1'b1;
				fifo_w.wr_data <= reordered_axi_rdata_comb;
				last_axi_rdata_ff <= last_axi_rdata_comb;
			end
			// If
			// - this is the last transfer,
			// - more than a full word is available,
			// - this is the last transaction, and
			// - cont is not set,
			// do an extra write cycle.
			extra_write <= axi_r.rlast & rlast_gt_full & (bursts_left == 1) & ~cont;
		end
		if (extra_write) begin
			fifo_w.wr_en <= 1'b1;
			fifo_w.wr_data <= last_axi_rdata_ff;
		end
	end
end

// ------- ------- ------- ------- ------- ------- ------- -------
//
// Read operation main
//
// ------- ------- ------- ------- ------- ------- ------- -------
// Reading initiation pulse
var logic read_burst_start;
var logic [(LEN_WIDTH-8-ALIGN_WIDTH)-1:0] full_bursts_left;
var logic [LEN_WIDTH-8-ALIGN_WIDTH:0] bursts_left;
var logic [7:0] beats_left;
var logic [ALIGN_WIDTH-1:0] extra_bytes;
var logic [AXI_ADDR_WIDTH-1:0] src_addr;
var logic cont;

var logic [ALIGN_WIDTH:0] last_write_bytes;

always_ff @(posedge clock) begin
	if (!reset_n) begin
		read_burst_start <= 1'b0;
		mem_r.done <= 1'b0;
		mem_r.busy <= 1'b0;
		current_offset <= '0;
	end
	else begin
		// Unpulse
		read_burst_start <= 1'b0;
		mem_r.done <= 1'b0;

		if (mem_r.busy == 1'b0 && mem_r.start) begin
			$display("mem_r.start pulse: .addr=%x .len=%d",
				mem_r.addr, mem_r.len);

			if (mem_r.len == 0) begin
				mem_r.done <= 1'b1;
				mem_r.error <= 1'b1;
			end
			else begin
				src_addr <= mem_r.addr;
				full_bursts_left <= mem_r.len[LEN_WIDTH-1:8+ALIGN_WIDTH];

				if (mem_r.len[8+ALIGN_WIDTH-1:0] != '0) begin
					bursts_left <= mem_r.len[LEN_WIDTH-1:8+ALIGN_WIDTH] + 1;
				end
				else begin
					bursts_left <= mem_r.len[LEN_WIDTH-1:8+ALIGN_WIDTH];
				end

				beats_left <= mem_r.len[8+ALIGN_WIDTH-1:ALIGN_WIDTH];
				extra_bytes <= mem_r.len[ALIGN_WIDTH-1:0];
				if (mem_r.len[ALIGN_WIDTH-1:0] == '0) begin
					last_write_bytes[ALIGN_WIDTH] <= 1'b1;
					last_write_bytes[ALIGN_WIDTH-1:0] <= current_offset;
				end
				else
					last_write_bytes <= current_offset + mem_r.len[ALIGN_WIDTH-1:0];
				cont <= mem_r.cont;
				mem_r.busy <= 1'b1;
				read_burst_start <= 1'b1;
			end
		end

		if (mem_r.busy == 1'b1 && read_burst_done) begin
			$display("read_burst_done pulse");

			if (bursts_left != 1) begin
				src_addr <= src_addr + MAX_NBYTES_PER_BURST[AXI_ADDR_WIDTH-1:0];
				full_bursts_left <= full_bursts_left - 1;
				bursts_left <= bursts_left - 1;
				read_burst_start <= 1'b1;
			end
			else begin
				mem_r.error <= 1'b0;
				mem_r.done <= 1'b1;
				mem_r.busy <= 1'b0;
				if (cont)
					current_offset <= last_write_bytes[ALIGN_WIDTH-1:0];
				else
					current_offset <= '0;
			end
		end
	end
end
	
endmodule
