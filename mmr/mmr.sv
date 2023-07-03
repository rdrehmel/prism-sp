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
import mmr_config::*;

module axi_lite_mmr #(
	parameter int REG_WIDTH = 32,
	parameter int IBRAM_SIZE,
	parameter int DBRAM_SIZE,
	parameter int RX_DATA_FIFO_SIZE = 0,
	parameter int RX_DATA_FIFO_WIDTH = 0,
	parameter int TX_DATA_FIFO_SIZE = 0,
	parameter int TX_DATA_FIFO_WIDTH = 0
) (
	input wire logic clock,
	input wire logic reset_n,

	axi_lite_write_address_channel.slave axi_aw,
	axi_lite_write_channel.slave axi_w,
	axi_lite_write_response_channel.slave axi_b,
	axi_lite_read_address_channel.slave axi_ar,
	axi_lite_read_channel.slave axi_r,

	mmr_readwrite_interface.slave mmr_rw,
	mmr_read_interface.slave mmr_r,
	mmr_intr_interface.slave mmr_i,

	output wire logic cpu_reset,

	output var logic [3:0] io_axi_axcache,
	output var logic [3:0] dma_axi_axcache,

	local_memory_interface.master instruction_bram_mmr,
	local_memory_interface.master data_bram_mmr
);

var logic cpu_reset_ff = 1'b1;
assign cpu_reset = cpu_reset_ff;

localparam int AXI_ARADDR_WIDTH = axi_ar.AXI_ARADDR_WIDTH;
localparam int AXI_RDATA_WIDTH = axi_r.AXI_RDATA_WIDTH;
localparam int AXI_AWADDR_WIDTH = axi_aw.AXI_AWADDR_WIDTH;
localparam int AXI_WDATA_WIDTH = axi_w.AXI_WDATA_WIDTH;

var logic [AXI_AWADDR_WIDTH-1:0] axi_awaddr;
var logic [AXI_WDATA_WIDTH-1:0] axi_wdata;

wire logic aw_hshake = axi_aw.awvalid && axi_aw.awready;
wire logic w_hshake = axi_w.wvalid && axi_w.wready;
wire logic b_hshake = axi_b.bvalid && axi_b.bready;
wire logic ar_hshake = axi_ar.arvalid && axi_ar.arready;
wire logic r_hshake = axi_r.rvalid && axi_r.rready;

var logic [1:0] axi_rresp_next;
var logic [AXI_RDATA_WIDTH-1:0] axi_rdata_next;

var logic got_aw_hshake;
var logic got_w_hshake;
var logic reset_n_prev;
wire logic reset_n_posedge = !reset_n_prev && reset_n;

localparam int BRAM_SIZE = IBRAM_SIZE + DBRAM_SIZE;
var logic [$clog2(BRAM_SIZE)-2-1:0] bram_addr;
var logic [31:0] bram_data;
assign instruction_bram_mmr.addr = bram_addr;
assign data_bram_mmr.addr = bram_addr;
assign instruction_bram_mmr.data_in = bram_data;
assign data_bram_mmr.data_in = bram_data;

assign mmr_r.data[MMR_R_REGN_IO_AXI_AXCACHE] = io_axi_axcache;
assign mmr_r.data[MMR_R_REGN_DMA_AXI_AXCACHE] = dma_axi_axcache;

task mmr_write(
	input var logic [AXI_AWADDR_WIDTH-1:0] awaddr,
	input var logic [AXI_WDATA_WIDTH-1:0] wdata
);
	axi_b.bresp <= 2'b00;

	case (awaddr[MMR_RANGE_WIDTH-1:0])
	REGOFF_CONTROL: begin
		mmr_rw.data[MMR_RW_REGN_CONTROL] <= wdata[7:0];
		cpu_reset_ff <= wdata[31];
	end

	REGOFF_BRAM_ADDR: begin
		bram_addr <= wdata[2 +: $bits(bram_addr)];
	end
	REGOFF_BRAM_DATA: begin
		bram_data <= wdata;
		if (~bram_addr[$clog2(IBRAM_SIZE)-2]) begin
			instruction_bram_mmr.en <= 1'b1;
			instruction_bram_mmr.be <= '1;
		end
		else begin
			data_bram_mmr.en <= 1'b1;
			data_bram_mmr.be <= '1;
		end
	end

	REGOFF_IO_AXI_AXCACHE: begin
		io_axi_axcache <= wdata[3:0];
	end

	REGOFF_DMA_AXI_AXCACHE: begin
		dma_axi_axcache <= wdata[3:0];
	end

	REGOFF_RESERVED0: begin
		mmr_r.data[MMR_R_REGN_RESERVED0] <= wdata;
	end

	REGOFF_RX_DMA_DESC_BASE + SIZEOF_REG*0: begin
		mmr_r.data[MMR_R_REGN_RX_DMA_DESC_BASE_0] <= wdata;
	end
	REGOFF_RX_DMA_DESC_BASE + SIZEOF_REG*1: begin
		mmr_r.data[MMR_R_REGN_RX_DMA_DESC_BASE_1] <= wdata;
	end
	REGOFF_TX_DMA_DESC_BASE + SIZEOF_REG*0: begin
		mmr_r.data[MMR_R_REGN_TX_DMA_DESC_BASE_0] <= wdata;
	end
	REGOFF_TX_DMA_DESC_BASE + SIZEOF_REG*1: begin
		mmr_r.data[MMR_R_REGN_TX_DMA_DESC_BASE_1] <= wdata;
	end
	REGOFF_IER_BASE + SIZEOF_REG*0: begin
		mmr_i.imr[0] <= mmr_i.imr[0] | wdata;
	end
	REGOFF_IER_BASE + SIZEOF_REG*1: begin
		mmr_i.imr[1] <= mmr_i.imr[1] | wdata;
	end
	REGOFF_IDR_BASE + SIZEOF_REG*0: begin
		mmr_i.imr[0] <= mmr_i.imr[0] & ~wdata;
	end
	REGOFF_IDR_BASE + SIZEOF_REG*1: begin
		mmr_i.imr[1] <= mmr_i.imr[1] & ~wdata;
	end
	REGOFF_ISR_BASE + SIZEOF_REG*0: begin
		mmr_i.isr[0] <= mmr_i.isr[0] & ~wdata;
	end
	REGOFF_ISR_BASE + SIZEOF_REG*1: begin
		mmr_i.isr[1] <= mmr_i.isr[1] & ~wdata;
	end
	default: begin
		axi_b.bvalid <= 1'b1;
		axi_b.bresp <= 2'b01;
	end
	endcase
endtask

always_ff @(posedge clock) begin
	reset_n_prev <= reset_n;
	if (!reset_n) begin
		axi_b.bvalid <= 1'b0;
		axi_b.bresp <= 2'b0;
		axi_aw.awready <= 1'b0;
		axi_w.wready <= 1'b0;
		got_aw_hshake <= 1'b0;
		got_w_hshake <= 1'b0;
		axi_awaddr <= '0;
		axi_wdata <= '0;

		for (int i = 0; i < mmr_rw.NREGS; i++)
			mmr_rw.data[i] <= '0;

		for (int i = 0; i < mmr_r.NREGS; i++) begin
			if (i != MMR_R_REGN_IO_AXI_AXCACHE && i != MMR_R_REGN_DMA_AXI_AXCACHE) begin
				mmr_r.data[i] <= '0;
			end
		end
		io_axi_axcache <= 4'b0000;
		dma_axi_axcache <= 4'b0000;
		mmr_r.data[MMR_R_REGN_RX_DATA_FIFO_SIZE] <= RX_DATA_FIFO_SIZE;
		mmr_r.data[MMR_R_REGN_RX_DATA_FIFO_WIDTH] <= RX_DATA_FIFO_WIDTH;
		mmr_r.data[MMR_R_REGN_TX_DATA_FIFO_SIZE] <= TX_DATA_FIFO_SIZE;
		mmr_r.data[MMR_R_REGN_TX_DATA_FIFO_WIDTH] <= TX_DATA_FIFO_WIDTH;

		for (int i = 0; i < mmr_i.N; i++) begin
			mmr_i.isr[i] <= '0;
			mmr_i.imr[i] <= '0;
		end

		instruction_bram_mmr.en <= 1'b0;
		data_bram_mmr.en <= 1'b0;
	end
	else begin
		// Unpulse
		instruction_bram_mmr.en <= 1'b0;
		data_bram_mmr.en <= 1'b0;

		if (mmr_rw.store) begin
			mmr_rw.data[mmr_rw.store_idx] <= mmr_rw.store_data;
		end
		for (int i = 0; i < mmr_i.N; i++) begin
			mmr_i.isr[i] <= mmr_i.isr[i] | mmr_i.isr_pulses[i];
		end

		if (reset_n_posedge) begin
			$display("RESET_N POSEDGE.");
			axi_aw.awready <= 1'b1;
			axi_w.wready <= 1'b1;
		end
		if (aw_hshake) begin
			$display("AW_HSHAKE for address %h.", axi_aw.awaddr);
			axi_awaddr <= axi_aw.awaddr;
			axi_aw.awready <= 1'b0;
			got_aw_hshake <= 1'b1;
		end
		if (w_hshake) begin
			$display("W_HSHAKE for data %h.", axi_w.wdata);
			axi_wdata <= axi_w.wdata;
			axi_w.wready <= 1'b0;
			got_w_hshake <= 1'b1;
		end
		if (b_hshake) begin
			$display("B_HSHAKE");
			// Unset our B handshake signal
			axi_b.bvalid <= 1'b0;
			// Set our AW and W handshake signals
			axi_aw.awready <= 1'b1;
			axi_w.wready <= 1'b1;
		end
		if (got_aw_hshake && got_w_hshake) begin
			axi_b.bvalid <= 1'b1;
			mmr_write(axi_awaddr, axi_wdata);
			// Reset the W and AW handshake state
			got_aw_hshake <= 1'b0;
			got_w_hshake <= 1'b0;
		end
	end
end

//
//
// AXI READ CHANNEL
//
//
always_comb begin
	axi_rresp_next = 2'b00;

	case (axi_ar.araddr[MMR_RANGE_WIDTH-1:0])
	REGOFF_CONTROL: begin
		axi_rdata_next[31] = cpu_reset_ff;
		axi_rdata_next[30:0] = mmr_rw.data[MMR_RW_REGN_CONTROL];
	end

	REGOFF_IO_AXI_AXCACHE: begin
		axi_rdata_next = { 28'h0000000, io_axi_axcache };
	end

	REGOFF_DMA_AXI_AXCACHE: begin
		axi_rdata_next = { 28'h0000000, dma_axi_axcache };
	end

	REGOFF_RESERVED0: begin
		axi_rdata_next = mmr_r.data[MMR_R_REGN_RESERVED0];
	end

	REGOFF_RX_DMA_DESC_BASE + SIZEOF_REG*0: begin
		axi_rdata_next = mmr_r.data[MMR_R_REGN_RX_DMA_DESC_BASE_0];
	end
	REGOFF_RX_DMA_DESC_BASE + SIZEOF_REG*1: begin
		axi_rdata_next = mmr_r.data[MMR_R_REGN_RX_DMA_DESC_BASE_1];
	end
	REGOFF_TX_DMA_DESC_BASE + SIZEOF_REG*0: begin
		axi_rdata_next = mmr_r.data[MMR_R_REGN_TX_DMA_DESC_BASE_0];
	end
	REGOFF_TX_DMA_DESC_BASE + SIZEOF_REG*1: begin
		axi_rdata_next = mmr_r.data[MMR_R_REGN_TX_DMA_DESC_BASE_1];
	end
	REGOFF_IMR_BASE + SIZEOF_REG*0: begin
		axi_rdata_next = mmr_i.imr[0];
	end
	REGOFF_IMR_BASE + SIZEOF_REG*1: begin
		axi_rdata_next = mmr_i.imr[1];
	end
	REGOFF_ISR_BASE + SIZEOF_REG*0: begin
		axi_rdata_next = mmr_i.isr[0];
	end
	REGOFF_ISR_BASE + SIZEOF_REG*1: begin
		axi_rdata_next = mmr_i.isr[1];
	end
	default: begin
		axi_rdata_next = '0;
		axi_rresp_next = 2'b10;
	end
	endcase
end

always_ff @(posedge clock) begin
	if (!reset_n) begin
		axi_ar.arready <= 1'b0;
		axi_r.rvalid <= 1'b0;
	end
	else begin
`ifdef DEBUG
		$display("---- ARVALID=%d ARREADY=%d RVALID=%d RREADY=%d",
			axi_ar.arvalid, 
			axi_ar.arready,
			axi_r.rvalid, 
			axi_r.rready);
		$display("---- AWVALID=%d AWREADY=%d WVALID=%d WREADY=%d BVALID=%d BREADY=%d",
			axi_aw.awvalid, 
			axi_aw.awready,
			axi_w.wvalid, 
			axi_w.wready,
			axi_b.bvalid, 
			axi_b.bready);
`endif
		if (reset_n_posedge) begin
			$display("RESET_N_POSEDGE in read task");
			axi_ar.arready <= 1'b1;
		end

		if (ar_hshake) begin
			$display("AR_HSHAKE for address %h", axi_ar.araddr);
			axi_ar.arready <= 1'b0;
			axi_r.rvalid <= 1'b1;
			axi_r.rdata <= axi_rdata_next;
			axi_r.rresp <= axi_rresp_next;
		end

		if (r_hshake) begin
			$display("R_HSHAKE");
			axi_ar.arready <= 1'b1;
			axi_r.rvalid <= 1'b0;
		end
	end
end

endmodule
