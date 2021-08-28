/*
 * Copyright (c) 2016-2021 Robert Drehmel
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
	parameter integer AXI_ADDR_WIDTH = 32,
	parameter integer AXI_DATA_WIDTH = 32
)
(
	input wire clock,
	input wire reset_n,

	// Interface to start memory writing process
	memory_write_interface.slave mem_w,
	// Interface to read from a FIFO
	fifo_read_interface.master fifo_r,

	// Interface of the actual AXI writing channel(s)
	axi_write_address_channel.master axi_aw,
	axi_write_channel.master axi_w,
	axi_write_response_channel.master axi_b
);

localparam integer MAX_NBYTES_PER_BURST = 256 * (AXI_DATA_WIDTH / 8);
localparam integer LEN_WIDTH = 16;

assign axi_aw.awid = '0;
// Size should be AXI_DATA_WIDTH, in 2^AWSIZE bytes, otherwise narrow bursts are
// used
localparam int AWSIZE = $clog2((AXI_DATA_WIDTH/8)-1);
assign axi_aw.awsize = AWSIZE[2:0];
// INCR burst type
assign axi_aw.awburst = 2'b01;
assign axi_aw.awlock = 0;
// Update value to 4'b0011 if coherent accesses to be used via the
// Zynq ACP port.
// Not Allocated, Modifiable, not Bufferable.
assign axi_aw.awcache = 4'b0010;
assign axi_aw.awprot = 3'h0;
assign axi_aw.awqos = 4'h0;
assign axi_aw.awuser = 1;
// XXX Only full AXI_DATA_WIDTH writes are currently supported.
assign axi_w.wstrb = {(AXI_DATA_WIDTH/8){1'b1}};
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

always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_aw.awvalid <= 1'b0;
	end
	else begin
		if (write_burst_start) begin
			axi_aw.awvalid <= 1'b1;
			axi_aw.awaddr <= dest_addr;

			if (bytes_left >= 16'(256 * (AXI_DATA_WIDTH / 8))) begin
				axi_aw.awlen <= 255;
			end
			else begin
				// See the comment in axi_to_fifo.sv for an explanation.
				localparam int ALIGN = $clog2(AXI_DATA_WIDTH / 8);
				if (bytes_left[ALIGN-1:0] != '0)
					axi_aw.awlen <= bytes_left[ALIGN +:8];
				else
					axi_aw.awlen <= bytes_left[ALIGN +:8] - 1;
			end
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
always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_w.wvalid <= 1'b0;
	end
	else begin
		if (write_burst_start) begin
			axi_w.wvalid <= 1'b1;
			axi_w.wdata <= fifo_r.rd_data;
			axi_w.wlast <= bytes_left == '0;
		end
		else if (w_hshake_not_last) begin
			axi_w.wvalid <= 1'b1;
			axi_w.wdata <= fifo_r.rd_data;
			axi_w.wlast <= w_hshake_count_comb == axi_aw.awlen;
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
	w_hshake_count_ff = w_hshake_count_comb;
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
var logic [LEN_WIDTH-1:0] bytes_left;
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
				bytes_left <= mem_w.len[LEN_WIDTH-1:0];
				mem_w.busy <= 1'b1;
				write_burst_start <= 1'b1;
			end
		end

		if (mem_w.busy == 1'b1 && write_burst_done) begin
			$display("write_burst_done pulse");

			// If bytes_left is > than the maximum transfer bytes,
			if (bytes_left > MAX_NBYTES_PER_BURST[LEN_WIDTH - 1:0]) begin
				dest_addr <= dest_addr + MAX_NBYTES_PER_BURST[AXI_ADDR_WIDTH-1:0];
				bytes_left <= bytes_left - MAX_NBYTES_PER_BURST[LEN_WIDTH - 1:0];
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
