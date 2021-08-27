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
// AXI[r] -> FIFO
module axi_to_fifo #
(
	parameter integer AXI_ADDR_WIDTH = 32,
	parameter integer AXI_DATA_WIDTH = 32
)
(
	input wire clock,
	input wire reset_n,

	// Interface to start the memory reading process
	memory_read_interface.slave mem_r,
	// Interface to write to a FIFO
	fifo_write_interface.master fifo_w,

	// Actual AXI memory interface for reading
	axi_read_address_channel.master axi_ar,
	axi_read_channel.master axi_r
);

localparam integer MAX_NBYTES_PER_BURST = 256 * (AXI_DATA_WIDTH / 8);
localparam integer LEN_WIDTH = 16;

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
// Update value to 4'b0011 if coherent accesses to be used via the
// Zynq ACP port.
// Not Allocated, Modifiable, not Bufferable.
assign axi_ar.arcache = 4'b0010;
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
// -> ARVALID
//
always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_ar.arvalid <= 1'b0;
	end
	else begin
		if (read_burst_start) begin
			axi_ar.arvalid <= 1'b1;
		end
		else if (ar_hshake) begin
			axi_ar.arvalid <= 1'b0;
		end
	end
end

//
// -> ARADDR, ARLEN, etc
// Everything depending on ARVALID.
//
always_ff @(posedge clock) begin
	if (!reset_n) begin
	end
	else begin
		if (read_burst_start) begin
			axi_ar.araddr <= src_addr;

			if (bytes_left >= 16'(256 * (AXI_DATA_WIDTH / 8))) begin
				axi_ar.arlen <= 255;
			end
			else begin
				localparam int ALIGN = $clog2((AXI_DATA_WIDTH / 8) - 1);
				axi_ar.arlen <= bytes_left[ALIGN +:8] - 1;
			end
		end
	end
end


// ------- ------- ------- ------- ------- ------- ------- -------
//
// AXI SECTION A2.6: Read Data (and Response) Channel
//
// ------- ------- ------- ------- ------- ------- ------- -------

//
// -> RREADY
//
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

var integer r_hshake_count;
always_ff @(posedge clock) begin
	if (!reset_n) begin
		r_hshake_count <= '0;
	end
	else begin
		if (read_burst_start)
			r_hshake_count <= '0;
		else if (r_hshake)
			r_hshake_count <= r_hshake_count + 1;
	end
end

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

always_ff @(posedge clock) begin
	if (!reset_n) begin
		fifo_w.wr_en <= 1'b0;
	end
	else begin
		// Unpulse
		fifo_w.wr_en <= 1'b0;

		if (r_hshake) begin
			fifo_w.wr_en <= 1'b1;
			fifo_w.wr_data <= axi_r.rdata;
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
var logic [LEN_WIDTH-1:0] bytes_left;
var logic [AXI_ADDR_WIDTH-1:0] src_addr;

always_ff @(posedge clock) begin
	if (!reset_n) begin
		read_burst_start <= 1'b0;
		mem_r.done <= 1'b0;
		mem_r.busy <= 1'b0;
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
				bytes_left <= mem_r.len[LEN_WIDTH-1:0];
				mem_r.busy <= 1'b1;
				read_burst_start <= 1'b1;
			end
		end

		if (mem_r.busy == 1'b1 && read_burst_done) begin
			$display("read_burst_done pulse");

			if (bytes_left > MAX_NBYTES_PER_BURST[LEN_WIDTH - 1:0]) begin
				src_addr <= src_addr + MAX_NBYTES_PER_BURST[AXI_ADDR_WIDTH-1:0];
				bytes_left <= bytes_left - MAX_NBYTES_PER_BURST[LEN_WIDTH - 1:0];
				read_burst_start <= 1'b1;
			end
			else begin
				mem_r.error <= 1'b0;
				mem_r.done <= 1'b1;
				mem_r.busy <= 1'b0;
			end
		end
	end
end
	
endmodule
