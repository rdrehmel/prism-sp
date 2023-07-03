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
module acpram_axi
#(
	parameter int AXI_ADDR_WIDTH = 32
)
(
	input wire logic clock,
	input wire logic resetn,

	input wire logic [15:0] acp_local_wstrb [4],
	input wire logic [15:0] acp_remote_wstrb_0,
	input wire logic [3:0] acp_remote_wstrb_0123,

	acpram_axi_interface.slave acpram_axi_i,
	// Interface to access the acpram.
	xpm_memory_tdpram_port_interface.master acpram_port_i,

	// AXI
	axi_write_address_channel.master axi_aw,
	axi_write_channel.master axi_w,
	axi_write_response_channel.master axi_b,
	axi_read_address_channel.master axi_ar,
	axi_read_channel.master axi_r
);

// ------- ------- ------- ------- ------- ------- ------- -------
// ------- ------- ------- ------- ------- ------- ------- -------
// AXI write channels
// ------- ------- ------- ------- ------- ------- ------- -------
// ------- ------- ------- ------- ------- ------- ------- -------
assign axi_aw.awaddr[39:32] = '0;
assign axi_aw.awlen[7:2] = '0;
assign axi_aw.awid = '0;
// The ACP port only allows a size of 128 bits (16 byte).
assign axi_aw.awsize = 3'h4;
// INCR burst type
assign axi_aw.awburst = 2'b01;
assign axi_aw.awlock = 0;
assign axi_aw.awcache = 4'b1111;
assign axi_aw.awprot = 3'b010;
assign axi_aw.awqos = 4'h0;
assign axi_aw.awuser = 2'b10;
assign axi_w.wuser = 0;

var logic [3:0] burstpipe_comb;
var logic [3:0] burstpipe_ff;

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

always_ff @(posedge clock) begin
	if (!resetn) begin
		axi_aw.awvalid <= 1'b0;
	end
	else begin
		if (write_burst_start) begin
			axi_aw.awvalid <= 1'b1;
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
`ifdef WRITE_STROBE_PIPE_IMPL
var logic [3:0] acp_remote_wstrb_0123_pipe;
`endif

always_ff @(posedge clock) begin
	if (!resetn) begin
		axi_w.wvalid <= 1'b0;
	end
	else begin
`ifdef WRITE_STROBE_PIPE_IMPL
		// We use the additional cycle here to prepare the write strobe pipe.
		if (write_burst_pre) begin
			acp_remote_wstrb_0123_pipe <= acp_remote_wstrb_0123;
		end
`endif
		if (write_burst_start || w_hshake_not_last) begin
			axi_w.wvalid <= 1'b1;
			axi_w.wdata <= acpram_port_i.dout;
			axi_w.wlast <= burstpipe_comb[0];
			if (|axi_aw.awlen == 1'b1) begin
`ifdef WRITE_STROBE_PIPE_IMPL
				axi_w.wstrb <= {16{acp_remote_wstrb_0123_pipe[0]}};
				acp_remote_wstrb_0123_pipe[0] <= acp_remote_wstrb_0123_pipe[1];
				acp_remote_wstrb_0123_pipe[1] <= acp_remote_wstrb_0123_pipe[2];
				acp_remote_wstrb_0123_pipe[2] <= acp_remote_wstrb_0123_pipe[3];
`else
				axi_w.wstrb <= {16{acp_remote_wstrb_0123[beatn]}};
`endif
			end
			else begin
				axi_w.wstrb <= acp_remote_wstrb_0;
			end
		end
		if (w_hshake_last) begin
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
	if (!resetn) begin
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

var logic write_burst_done;
always_ff @(posedge clock) begin
	if (!resetn) begin
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
// ------- ------- ------- ------- ------- ------- ------- -------
// AXI read channels
// ------- ------- ------- ------- ------- ------- ------- -------
// ------- ------- ------- ------- ------- ------- ------- -------
wire logic ar_hshake = axi_ar.arvalid && axi_ar.arready;
wire logic r_hshake = axi_r.rvalid && axi_r.rready;
wire logic r_hshake_last = r_hshake && axi_r.rlast;
//
// Set up the AXI Read Channel interface
//
// Read Address
assign axi_ar.araddr[39:32] = '0;
assign axi_ar.arlen[7:2] = '0;
assign axi_ar.arid = '0;
assign axi_ar.arsize = 3'h4;
// INCR burst type
assign axi_ar.arburst = 2'b01;
assign axi_ar.arlock = 1'b0;
assign axi_ar.arcache = 4'b1111;
assign axi_ar.arprot = 3'b010;
assign axi_ar.arqos = 4'h0;
assign axi_ar.aruser = 2'b10;

// ------- ------- ------- ------- ------- ------- ------- -------
//
// AXI SECTION A2.5: Read Address Channel
//
// ------- ------- ------- ------- ------- ------- ------- -------
always_ff @(posedge clock) begin
	if (!resetn) begin
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

// ------- ------- ------- ------- ------- ------- ------- -------
//
// AXI SECTION A2.6: Read Data (and Response) Channel
//
// ------- ------- ------- ------- ------- ------- ------- -------
// slave asserts RVALID and keeps it asserted.
// When master is ready to accept data, master asserts RREADY
// On the next clock posedge where both RVALID(S) and RREADY(M)
// are asserted, the data in RDATA is transferred.
//
always_ff @(posedge clock) begin
	if (!resetn) begin
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

// We need to refill acpram_port_i.dout by asserting acpram_read
// exactly at the clock cycles in which we consume it.
// Note that we actually read too much here for both 1 and 4 length
// AXI transactions. But it doesn't do any harm and we don't want
// to add even more logic to this combinational path.
wire logic acpram_read = write_burst_pre || write_burst_start || w_hshake_not_last;
var logic acpram_write;
assign acpram_port_i.en = acpram_read | acpram_write;

var logic [1:0] beatn;

always_ff @(posedge clock) begin
	if (!resetn) begin
		beatn <= '0;
	end
	else begin
		if (acpram_axi_i.busy == 1'b0 && (acpram_axi_i.write || acpram_axi_i.read)) begin
			beatn <= '0;
		end
		if (w_hshake || r_hshake) begin
			beatn <= beatn + 1;
		end
	end
end

always_ff @(posedge clock) begin
	if (!resetn) begin
		acpram_write <= 1'b0;
		acpram_port_i.we <= '0;
	end
	else begin
		// Unpulse
		acpram_write <= 1'b0;
		acpram_port_i.we <= '0;

		if (r_hshake) begin
			acpram_write <= 1'b1;
			acpram_port_i.we <= acp_local_wstrb[beatn];
			acpram_port_i.din <= axi_r.rdata;
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
	if (!resetn) begin
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

// ------- ------- ------- ------- ------- ------- ------- -------
//
// Operation main
/*
------- ------- ------- ------- ------- ------- ------- ------- ------- -------|
 * Writing initiation pulse
 */
var logic write_burst_pre;
var logic write_burst_start;
var logic read_burst_start;

always_ff @(posedge clock) begin
	if (!resetn) begin
		write_burst_pre <= 1'b0;
		write_burst_start <= 1'b0;
		read_burst_start <= 1'b0;
		acpram_axi_i.busy <= 1'b0;
		acpram_axi_i.done <= 1'b0;
	end
	else begin
		write_burst_pre <= 1'b0;
		write_burst_start <= 1'b0;
		read_burst_start <= 1'b0;
		acpram_axi_i.done <= 1'b0;

		if (acpram_axi_i.busy == 1'b0 && acpram_axi_i.write) begin
			$display("acpram_axi_i.write pulse: .acpram_addr=%x .axi_addr=%x .len=%d",
				acpram_axi_i.acpram_addr, acpram_axi_i.axi_addr, acpram_axi_i.len);

			axi_aw.awaddr[31:0] <= acpram_axi_i.axi_addr;
			// This sets AWLEN
			// to 0 (1 transfer)  for acpram_axi_i.len==0 and
			// to 3 (4 transfers) for acpram_axi_i.len==1
			axi_aw.awlen[0] <= acpram_axi_i.len;
			axi_aw.awlen[1] <= acpram_axi_i.len;
			axi_aw.awaddr <= acpram_axi_i.axi_addr;
			acpram_port_i.addr <= acpram_axi_i.acpram_addr;
			acpram_axi_i.busy <= 1'b1;
			write_burst_pre <= 1'b1;
		end

		if (write_burst_pre) begin
			// We need this extra cycle to preload from ACPRAM.
			write_burst_start <= 1'b1;
		end

		if (acpram_axi_i.busy == 1'b1 && write_burst_done) begin
			$display("write_burst_done pulse");

			// XXX error handling
			acpram_axi_i.error <= 1'b0;
			// done is pulsed for 1 cycle.
			acpram_axi_i.done <= 1'b1;
			acpram_axi_i.busy <= 1'b0;
		end

		if (acpram_axi_i.busy == 1'b0 && acpram_axi_i.read) begin
			$display("acpram_axi_i.read pulse: .acpram_addr=%x .axi_addr=%x .len=%d",
				acpram_axi_i.acpram_addr, acpram_axi_i.axi_addr, acpram_axi_i.len);

			axi_ar.araddr[31:0] <= acpram_axi_i.axi_addr;
			// This sets ARLEN
			// to 0 (1 transfer)  for acpram_axi_i.len==0 and
			// to 3 (4 transfers) for acpram_axi_i.len==1
			axi_ar.arlen[0] <= acpram_axi_i.len;
			axi_ar.arlen[1] <= acpram_axi_i.len;
			axi_ar.araddr <= acpram_axi_i.axi_addr;

			acpram_port_i.addr <= acpram_axi_i.acpram_addr;
			acpram_axi_i.busy <= 1'b1;
			read_burst_start <= 1'b1;
		end
		if (acpram_axi_i.busy == 1'b1 && read_burst_done) begin
			$display("read_burst_done pulse");

			// XXX error handling
			acpram_axi_i.error <= 1'b0;
			// done is pulsed for 1 cycle.
			acpram_axi_i.done <= 1'b1;
			acpram_axi_i.busy <= 1'b0;
		end
		if (acpram_port_i.en) begin
			acpram_port_i.addr <= acpram_port_i.addr + 1;
		end
	end
end

always_comb begin
	burstpipe_comb = burstpipe_ff;

	if (!resetn) begin
		burstpipe_comb = '0;
	end
	else begin
		if (write_burst_start) begin
			// when the write burst starts, initialize
			// the burstpipe to either 4'b0001 or 4'b1000.
			burstpipe_comb[0] = ~axi_aw.awlen[0];
			burstpipe_comb[1] = 1'b0;
			burstpipe_comb[2] = 1'b0;
			burstpipe_comb[3] = axi_aw.awlen[0];
		end
		if (read_burst_start) begin
			// when the read burst starts, initialize
			// the burstpipe to either 4'b0001 or 4'b1000.
			burstpipe_comb[0] = ~axi_ar.arlen[0];
			burstpipe_comb[1] = 1'b0;
			burstpipe_comb[2] = 1'b0;
			burstpipe_comb[3] = axi_ar.arlen[0];
		end
		if (w_hshake || r_hshake) begin
			// Shift the burstpipe right with each write or read handshake.
			burstpipe_comb[0] = burstpipe_ff[1];
			burstpipe_comb[1] = burstpipe_ff[2];
			burstpipe_comb[2] = burstpipe_ff[3];
			burstpipe_comb[3] = 1'b0;
		end
	end
end

always_ff @(posedge clock) begin
	burstpipe_ff <= burstpipe_comb;
end

endmodule
