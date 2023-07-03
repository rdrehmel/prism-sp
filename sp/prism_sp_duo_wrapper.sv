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
import taiga_config::*;
import taiga_types::*;
import l2_config_and_types::*;

module prism_sp_duo_wrapper #(
	parameter int IBRAM_SIZE = 2**15,
	parameter int DBRAM_SIZE = 2**15,
	parameter int ACPBRAM_SIZE = 2*64*8,

	parameter int RX_DATA_FIFO_SIZE = 2**16,
	parameter int TX_DATA_FIFO_SIZE = 2**16,

	parameter int C_M_AXI_IO_ADDR_WIDTH = 32,
	parameter int C_M_AXI_IO_DATA_WIDTH = 32,
	parameter int C_M_AXI_ACP_ADDR_WIDTH = 40,
	parameter int C_M_AXI_ACP_DATA_WIDTH = 128,
	parameter int C_M_AXI_DMA_ADDR_WIDTH = 32,
	parameter int C_M_AXI_DMA_DATA_WIDTH = 32,
	parameter int C_S_AXIL_ADDR_WIDTH = 32,
	parameter int C_S_AXIL_DATA_WIDTH = 32
)
(
	input wire clock,
	input wire resetn,

	output wire gem_irq,
	output wire gem_irq_rx,
	output wire gem_irq_tx,

	/*
	 * AXI-lite slave interface
	 */
	input wire s_axil_0_awvalid,
	output wire s_axil_0_awready,
	input wire [C_S_AXIL_ADDR_WIDTH-1:0] s_axil_0_awaddr,
	input wire [2:0] s_axil_0_awprot,

	input wire s_axil_0_wvalid,
	output wire s_axil_0_wready,
	input wire [C_S_AXIL_DATA_WIDTH-1:0] s_axil_0_wdata,
	input wire [(C_S_AXIL_DATA_WIDTH/8)-1:0] s_axil_0_wstrb,

	output wire s_axil_0_bvalid,
	input wire s_axil_0_bready,
	output wire [1:0] s_axil_0_bresp,

	input wire s_axil_0_arvalid,
	output wire s_axil_0_arready,
	input wire [C_S_AXIL_ADDR_WIDTH-1:0] s_axil_0_araddr,
	input wire [2:0] s_axil_0_arprot,

	output wire s_axil_0_rvalid,
	input wire s_axil_0_rready,
	output wire [C_S_AXIL_DATA_WIDTH-1:0] s_axil_0_rdata,
	output wire [1:0] s_axil_0_rresp,

	/*
	 * AXI-lite slave interface
	 */
	input wire s_axil_1_awvalid,
	output wire s_axil_1_awready,
	input wire [C_S_AXIL_ADDR_WIDTH-1:0] s_axil_1_awaddr,
	input wire [2:0] s_axil_1_awprot,

	input wire s_axil_1_wvalid,
	output wire s_axil_1_wready,
	input wire [C_S_AXIL_DATA_WIDTH-1:0] s_axil_1_wdata,
	input wire [(C_S_AXIL_DATA_WIDTH/8)-1:0] s_axil_1_wstrb,

	output wire s_axil_1_bvalid,
	input wire s_axil_1_bready,
	output wire [1:0] s_axil_1_bresp,

	input wire s_axil_1_arvalid,
	output wire s_axil_1_arready,
	input wire [C_S_AXIL_ADDR_WIDTH-1:0] s_axil_1_araddr,
	input wire [2:0] s_axil_1_arprot,

	output wire s_axil_1_rvalid,
	input wire s_axil_1_rready,
	output wire [C_S_AXIL_DATA_WIDTH-1:0] s_axil_1_rdata,
	output wire [1:0] s_axil_1_rresp,

	/*
	 * IO access
	 */
	output wire m_axi_io_0_arvalid,
	input wire m_axi_io_0_arready,
	output wire [C_M_AXI_IO_ADDR_WIDTH-1:0] m_axi_io_0_araddr,
	output wire [7:0] m_axi_io_0_arlen,
	output wire [2:0] m_axi_io_0_arsize,
	output wire [1:0] m_axi_io_0_arburst,
	output wire [3:0] m_axi_io_0_arcache,
	output wire [2:0] m_axi_io_0_arprot,
	output wire [5:0] m_axi_io_0_arid,
	output wire m_axi_io_0_arlock,
	input wire m_axi_io_0_rvalid,
	output wire m_axi_io_0_rready,
	input wire [C_M_AXI_IO_DATA_WIDTH-1:0] m_axi_io_0_rdata,
	input wire [1:0] m_axi_io_0_rresp,
	input wire m_axi_io_0_rlast,
	input wire [5:0] m_axi_io_0_rid,
	output wire m_axi_io_0_awvalid,
	input wire m_axi_io_0_awready,
	output wire [C_M_AXI_IO_ADDR_WIDTH-1:0] m_axi_io_0_awaddr,
	output wire [7:0] m_axi_io_0_awlen,
	output wire [2:0] m_axi_io_0_awsize,
	output wire [1:0] m_axi_io_0_awburst,
	output wire [3:0] m_axi_io_0_awcache,
	output wire [2:0] m_axi_io_0_awprot,
	output wire [5:0] m_axi_io_0_awid,
	output wire m_axi_io_0_awlock,
	output wire m_axi_io_0_wvalid,
	input wire m_axi_io_0_wready,
	output wire [C_M_AXI_IO_DATA_WIDTH-1:0] m_axi_io_0_wdata,
	output wire [(C_M_AXI_IO_DATA_WIDTH/8)-1:0] m_axi_io_0_wstrb,
	output wire m_axi_io_0_wlast,
	input wire m_axi_io_0_bvalid,
	output wire m_axi_io_0_bready,
	input wire [1:0] m_axi_io_0_bresp,
	input wire [5:0] m_axi_io_0_bid,

	/*
	 * IO access
	 */
	output wire m_axi_io_1_arvalid,
	input wire m_axi_io_1_arready,
	output wire [C_M_AXI_IO_ADDR_WIDTH-1:0] m_axi_io_1_araddr,
	output wire [7:0] m_axi_io_1_arlen,
	output wire [2:0] m_axi_io_1_arsize,
	output wire [1:0] m_axi_io_1_arburst,
	output wire [3:0] m_axi_io_1_arcache,
	output wire [2:0] m_axi_io_1_arprot,
	output wire [5:0] m_axi_io_1_arid,
	output wire m_axi_io_1_arlock,
	input wire m_axi_io_1_rvalid,
	output wire m_axi_io_1_rready,
	input wire [C_M_AXI_IO_DATA_WIDTH-1:0] m_axi_io_1_rdata,
	input wire [1:0] m_axi_io_1_rresp,
	input wire m_axi_io_1_rlast,
	input wire [5:0] m_axi_io_1_rid,
	output wire m_axi_io_1_awvalid,
	input wire m_axi_io_1_awready,
	output wire [C_M_AXI_IO_ADDR_WIDTH-1:0] m_axi_io_1_awaddr,
	output wire [7:0] m_axi_io_1_awlen,
	output wire [2:0] m_axi_io_1_awsize,
	output wire [1:0] m_axi_io_1_awburst,
	output wire [3:0] m_axi_io_1_awcache,
	output wire [2:0] m_axi_io_1_awprot,
	output wire [5:0] m_axi_io_1_awid,
	output wire m_axi_io_1_awlock,
	output wire m_axi_io_1_wvalid,
	input wire m_axi_io_1_wready,
	output wire [C_M_AXI_IO_DATA_WIDTH-1:0] m_axi_io_1_wdata,
	output wire [(C_M_AXI_IO_DATA_WIDTH/8)-1:0] m_axi_io_1_wstrb,
	output wire m_axi_io_1_wlast,
	input wire m_axi_io_1_bvalid,
	output wire m_axi_io_1_bready,
	input wire [1:0] m_axi_io_1_bresp,
	input wire [5:0] m_axi_io_1_bid,

	/*
	 * ACP access
	 */
	output wire [5:0] m_axi_acp_0_awid,
	output wire [C_M_AXI_ACP_ADDR_WIDTH-1:0] m_axi_acp_0_awaddr,
	output wire [7:0] m_axi_acp_0_awlen,
	output wire [2:0] m_axi_acp_0_awsize,
	output wire [1:0] m_axi_acp_0_awburst,
	output wire m_axi_acp_0_awlock,
	output wire [3:0] m_axi_acp_0_awcache,
	output wire [2:0] m_axi_acp_0_awprot,
	output wire [3:0] m_axi_acp_0_awqos,
	// No AWREGION
	output wire [1:0] m_axi_acp_0_awuser,
	output wire m_axi_acp_0_awvalid,
	input wire m_axi_acp_0_awready,

	output wire [C_M_AXI_ACP_DATA_WIDTH-1:0] m_axi_acp_0_wdata,
	output wire [(C_M_AXI_ACP_DATA_WIDTH/8)-1:0] m_axi_acp_0_wstrb,
	output wire m_axi_acp_0_wlast,
	// No WUSER
	output wire m_axi_acp_0_wvalid,
	input wire m_axi_acp_0_wready,

	input wire [5:0] m_axi_acp_0_bid,
	input wire [1:0] m_axi_acp_0_bresp,
	// No BUSER
	input wire m_axi_acp_0_bvalid,
	output wire m_axi_acp_0_bready,

	output wire [5:0] m_axi_acp_0_arid,
	output wire [C_M_AXI_ACP_ADDR_WIDTH-1:0] m_axi_acp_0_araddr,
	output wire [7:0] m_axi_acp_0_arlen,
	output wire [2:0] m_axi_acp_0_arsize,
	output wire [1:0] m_axi_acp_0_arburst,
	output wire m_axi_acp_0_arlock,
	output wire [3:0] m_axi_acp_0_arcache,
	output wire [2:0] m_axi_acp_0_arprot,
	output wire [3:0] m_axi_acp_0_arqos,
	// No AWREGION
	output wire [1:0] m_axi_acp_0_aruser,
	output wire m_axi_acp_0_arvalid,
	input wire m_axi_acp_0_arready,

	input wire [5:0] m_axi_acp_0_rid,
	input wire [C_M_AXI_ACP_DATA_WIDTH-1:0] m_axi_acp_0_rdata,
	input wire [1:0] m_axi_acp_0_rresp,
	input wire m_axi_acp_0_rlast,
	// No RUSER
	input wire m_axi_acp_0_rvalid,
	output wire m_axi_acp_0_rready,

	/*
	 * ACP access
	 */
	output wire [5:0] m_axi_acp_1_awid,
	output wire [C_M_AXI_ACP_ADDR_WIDTH-1:0] m_axi_acp_1_awaddr,
	output wire [7:0] m_axi_acp_1_awlen,
	output wire [2:0] m_axi_acp_1_awsize,
	output wire [1:0] m_axi_acp_1_awburst,
	output wire m_axi_acp_1_awlock,
	output wire [3:0] m_axi_acp_1_awcache,
	output wire [2:0] m_axi_acp_1_awprot,
	output wire [3:0] m_axi_acp_1_awqos,
	// No AWREGION
	output wire [1:0] m_axi_acp_1_awuser,
	output wire m_axi_acp_1_awvalid,
	input wire m_axi_acp_1_awready,

	output wire [C_M_AXI_ACP_DATA_WIDTH-1:0] m_axi_acp_1_wdata,
	output wire [(C_M_AXI_ACP_DATA_WIDTH/8)-1:0] m_axi_acp_1_wstrb,
	output wire m_axi_acp_1_wlast,
	// No WUSER
	output wire m_axi_acp_1_wvalid,
	input wire m_axi_acp_1_wready,

	input wire [5:0] m_axi_acp_1_bid,
	input wire [1:0] m_axi_acp_1_bresp,
	// No BUSER
	input wire m_axi_acp_1_bvalid,
	output wire m_axi_acp_1_bready,

	output wire [5:0] m_axi_acp_1_arid,
	output wire [C_M_AXI_ACP_ADDR_WIDTH-1:0] m_axi_acp_1_araddr,
	output wire [7:0] m_axi_acp_1_arlen,
	output wire [2:0] m_axi_acp_1_arsize,
	output wire [1:0] m_axi_acp_1_arburst,
	output wire m_axi_acp_1_arlock,
	output wire [3:0] m_axi_acp_1_arcache,
	output wire [2:0] m_axi_acp_1_arprot,
	output wire [3:0] m_axi_acp_1_arqos,
	// No ARREGION
	output wire [1:0] m_axi_acp_1_aruser,
	output wire m_axi_acp_1_arvalid,
	input wire m_axi_acp_1_arready,

	input wire [5:0] m_axi_acp_1_rid,
	input wire [C_M_AXI_ACP_DATA_WIDTH-1:0] m_axi_acp_1_rdata,
	input wire [1:0] m_axi_acp_1_rresp,
	input wire m_axi_acp_1_rlast,
	// No RUSER
	input wire m_axi_acp_1_rvalid,
	output wire m_axi_acp_1_rready,

	/*
	 * GEM DMA
	 */
	input wire m_axi_dma_arready,
	output wire m_axi_dma_arvalid,
	output wire [C_M_AXI_DMA_ADDR_WIDTH-1:0] m_axi_dma_araddr,
	output wire [7:0] m_axi_dma_arlen,
	output wire [2:0] m_axi_dma_arsize,
	output wire [1:0] m_axi_dma_arburst,
	output wire [3:0] m_axi_dma_arcache,
	output wire [5:0] m_axi_dma_arid,
	output wire m_axi_dma_rready,
	input wire m_axi_dma_rvalid,
	input wire [C_M_AXI_DMA_DATA_WIDTH-1:0] m_axi_dma_rdata,
	input wire [1:0] m_axi_dma_rresp,
	input wire m_axi_dma_rlast,
	input wire [5:0] m_axi_dma_rid,
	input wire m_axi_dma_awready,
	output wire m_axi_dma_awvalid,
	output wire [C_M_AXI_DMA_ADDR_WIDTH-1:0] m_axi_dma_awaddr,
	output wire [7:0] m_axi_dma_awlen,
	output wire [2:0] m_axi_dma_awsize,
	output wire [1:0] m_axi_dma_awburst,
	output wire [3:0] m_axi_dma_awcache,
	output wire [5:0] m_axi_dma_awid,
	input wire m_axi_dma_wready,
	output wire m_axi_dma_wvalid,
	output wire [C_M_AXI_DMA_DATA_WIDTH-1:0] m_axi_dma_wdata,
	output wire [(C_M_AXI_DMA_DATA_WIDTH/8)-1:0] m_axi_dma_wstrb,
	output wire m_axi_dma_wlast,
	input wire m_axi_dma_bvalid,
	output wire m_axi_dma_bready,
	input wire [1:0] m_axi_dma_bresp,
	input wire [5:0] m_axi_dma_bid,

	/*
	 * GEM Interface
	 */
	input wire gem_tx_clock,
	input wire gem_tx_resetn,
	output wire gem_tx_r_data_rdy,
	input wire gem_tx_r_rd,
	output wire gem_tx_r_valid,
	output wire [7:0] gem_tx_r_data,
	output wire gem_tx_r_sop,
	output wire gem_tx_r_eop,
	output wire gem_tx_r_err,
	output wire gem_tx_r_underflow,
	output wire gem_tx_r_flushed,
	output wire gem_tx_r_control,
	input wire [3:0] gem_tx_r_status,
	input wire gem_tx_r_fixed_lat,
	input wire gem_dma_tx_end_tog,
	output wire gem_dma_tx_status_tog,

	input wire gem_rx_clock,
	input wire gem_rx_resetn,
	input wire gem_rx_w_wr,
	input wire [31:0] gem_rx_w_data,
	input wire gem_rx_w_sop,
	input wire gem_rx_w_eop,
	input wire [44:0] gem_rx_w_status,
	input wire gem_rx_w_err,
	output wire gem_rx_w_overflow,
	input wire gem_rx_w_flush
);

localparam int IBRAM_WIDTH = 32;
localparam int DBRAM_WIDTH = 32;
localparam int RX_META_FIFO_WIDTH = 32;
localparam int RX_DATA_FIFO_WIDTH = C_M_AXI_DMA_DATA_WIDTH;
localparam int TX_META_FIFO_WIDTH = 32;
localparam int TX_DATA_FIFO_WIDTH = C_M_AXI_DMA_DATA_WIDTH;

axi_lite_write_address_channel #(.AXI_AWADDR_WIDTH(C_S_AXIL_ADDR_WIDTH)) s_axil_0_aw();
assign s_axil_0_aw.awvalid = s_axil_0_awvalid;
assign s_axil_0_awready = s_axil_0_aw.awready;
assign s_axil_0_aw.awaddr = s_axil_0_awaddr;
assign s_axil_0_aw.awprot = s_axil_0_awprot;
axi_lite_write_channel #(.AXI_WDATA_WIDTH(C_S_AXIL_DATA_WIDTH)) s_axil_0_w();
assign s_axil_0_w.wvalid = s_axil_0_wvalid;
assign s_axil_0_wready = s_axil_0_w.wready;
assign s_axil_0_w.wdata = s_axil_0_wdata;
assign s_axil_0_w.wstrb = s_axil_0_wstrb;
axi_lite_write_response_channel s_axil_0_b();
assign s_axil_0_bvalid = s_axil_0_b.bvalid;
assign s_axil_0_b.bready = s_axil_0_bready;
assign s_axil_0_bresp = s_axil_0_b.bresp;
axi_lite_read_address_channel #(.AXI_ARADDR_WIDTH(C_S_AXIL_ADDR_WIDTH)) s_axil_0_ar();
assign s_axil_0_ar.arvalid = s_axil_0_arvalid;
assign s_axil_0_arready = s_axil_0_ar.arready;
assign s_axil_0_ar.araddr = s_axil_0_araddr;
assign s_axil_0_ar.arprot = s_axil_0_arprot;
axi_lite_read_channel #(.AXI_RDATA_WIDTH(C_S_AXIL_DATA_WIDTH)) s_axil_0_r();
assign s_axil_0_rvalid = s_axil_0_r.rvalid;
assign s_axil_0_r.rready = s_axil_0_rready;
assign s_axil_0_rdata = s_axil_0_r.rdata;
assign s_axil_0_rresp = s_axil_0_r.rresp;

axi_lite_write_address_channel #(.AXI_AWADDR_WIDTH(C_S_AXIL_ADDR_WIDTH)) s_axil_1_aw();
assign s_axil_1_aw.awvalid = s_axil_1_awvalid;
assign s_axil_1_awready = s_axil_1_aw.awready;
assign s_axil_1_aw.awaddr = s_axil_1_awaddr;
assign s_axil_1_aw.awprot = s_axil_1_awprot;
axi_lite_write_channel #(.AXI_WDATA_WIDTH(C_S_AXIL_DATA_WIDTH)) s_axil_1_w();
assign s_axil_1_w.wvalid = s_axil_1_wvalid;
assign s_axil_1_wready = s_axil_1_w.wready;
assign s_axil_1_w.wdata = s_axil_1_wdata;
assign s_axil_1_w.wstrb = s_axil_1_wstrb;
axi_lite_write_response_channel s_axil_1_b();
assign s_axil_1_bvalid = s_axil_1_b.bvalid;
assign s_axil_1_b.bready = s_axil_1_bready;
assign s_axil_1_bresp = s_axil_1_b.bresp;
axi_lite_read_address_channel #(.AXI_ARADDR_WIDTH(C_S_AXIL_ADDR_WIDTH)) s_axil_1_ar();
assign s_axil_1_ar.arvalid = s_axil_1_arvalid;
assign s_axil_1_arready = s_axil_1_ar.arready;
assign s_axil_1_ar.araddr = s_axil_1_araddr;
assign s_axil_1_ar.arprot = s_axil_1_arprot;
axi_lite_read_channel #(.AXI_RDATA_WIDTH(C_S_AXIL_DATA_WIDTH)) s_axil_1_r();
assign s_axil_1_rvalid = s_axil_1_r.rvalid;
assign s_axil_1_r.rready = s_axil_1_rready;
assign s_axil_1_rdata = s_axil_1_r.rdata;
assign s_axil_1_rresp = s_axil_1_r.rresp;

/*
 * AXI IO
 */
axi_interface #(
	.C_M_AXI_ADDR_WIDTH(C_M_AXI_IO_ADDR_WIDTH),
	.C_M_AXI_DATA_WIDTH(C_M_AXI_IO_DATA_WIDTH)
) m_axi_io_0();
// AR
// assign m_axi_arid = m_axi.arid;
assign m_axi_io_0_arvalid = m_axi_io_0.arvalid;
assign m_axi_io_0_arlock = m_axi_io_0.arlock;
assign m_axi_io_0_araddr = m_axi_io_0.araddr;
assign m_axi_io_0_arlen = m_axi_io_0.arlen;
assign m_axi_io_0_arsize = m_axi_io_0.arsize;
assign m_axi_io_0_arburst = m_axi_io_0.arburst;
assign m_axi_io_0_arcache = m_axi_io_0.arcache;
assign m_axi_io_0_arprot = m_axi_io_0.arprot;
assign m_axi_io_0.arready = m_axi_io_0_arready;
// R
// assign m_axi_io_0_rid = m_axi.rid;
assign m_axi_io_0.rvalid = m_axi_io_0_rvalid;
assign m_axi_io_0.rdata = m_axi_io_0_rdata;
assign m_axi_io_0.rresp = m_axi_io_0_rresp;
assign m_axi_io_0.rlast = m_axi_io_0_rlast;
assign m_axi_io_0_rready = m_axi_io_0.rready;
// AW
assign m_axi_io_0_awvalid = m_axi_io_0.awvalid;
assign m_axi_io_0_awlock = m_axi_io_0.awlock;
assign m_axi_io_0_awaddr = m_axi_io_0.awaddr;
assign m_axi_io_0_awlen = m_axi_io_0.awlen;
assign m_axi_io_0_awsize = m_axi_io_0.awsize;
assign m_axi_io_0_awburst = m_axi_io_0.awburst;
assign m_axi_io_0_awcache = m_axi_io_0.awcache;
assign m_axi_io_0_awprot = m_axi_io_0.awprot;
assign m_axi_io_0.awready = m_axi_io_0_awready;
// W
assign m_axi_io_0_wvalid = m_axi_io_0.wvalid;
assign m_axi_io_0_wdata = m_axi_io_0.wdata;
assign m_axi_io_0_wstrb = m_axi_io_0.wstrb;
assign m_axi_io_0_wlast = m_axi_io_0.wlast;
assign m_axi_io_0.wready = m_axi_io_0_wready;
// B
// assign m_axi_io_0_bid = m_axi.bid;
assign m_axi_io_0.bvalid = m_axi_io_0_bvalid;
assign m_axi_io_0.bresp = m_axi_io_0_bresp;
assign m_axi_io_0_bready = m_axi_io_0.bready;

axi_interface #(
	.C_M_AXI_ADDR_WIDTH(C_M_AXI_IO_ADDR_WIDTH),
	.C_M_AXI_DATA_WIDTH(C_M_AXI_IO_DATA_WIDTH)
) m_axi_io_1();
// AR
// assign m_axi_arid = m_axi.arid;
assign m_axi_io_1_arvalid = m_axi_io_1.arvalid;
assign m_axi_io_1_arlock = m_axi_io_1.arlock;
assign m_axi_io_1_araddr = m_axi_io_1.araddr;
assign m_axi_io_1_arlen = m_axi_io_1.arlen;
assign m_axi_io_1_arsize = m_axi_io_1.arsize;
assign m_axi_io_1_arburst = m_axi_io_1.arburst;
assign m_axi_io_1_arcache = m_axi_io_1.arcache;
assign m_axi_io_1_arprot = m_axi_io_1.arprot;
assign m_axi_io_1.arready = m_axi_io_1_arready;
// R
// assign m_axi_io_1_rid = m_axi.rid;
assign m_axi_io_1.rvalid = m_axi_io_1_rvalid;
assign m_axi_io_1.rdata = m_axi_io_1_rdata;
assign m_axi_io_1.rresp = m_axi_io_1_rresp;
assign m_axi_io_1.rlast = m_axi_io_1_rlast;
assign m_axi_io_1_rready = m_axi_io_1.rready;
// AW
assign m_axi_io_1_awvalid = m_axi_io_1.awvalid;
assign m_axi_io_1_awlock = m_axi_io_1.awlock;
assign m_axi_io_1_awaddr = m_axi_io_1.awaddr;
assign m_axi_io_1_awlen = m_axi_io_1.awlen;
assign m_axi_io_1_awsize = m_axi_io_1.awsize;
assign m_axi_io_1_awburst = m_axi_io_1.awburst;
assign m_axi_io_1_awcache = m_axi_io_1.awcache;
assign m_axi_io_1_awprot = m_axi_io_1.awprot;
assign m_axi_io_1.awready = m_axi_io_1_awready;
// W
assign m_axi_io_1_wvalid = m_axi_io_1.wvalid;
assign m_axi_io_1_wdata = m_axi_io_1.wdata;
assign m_axi_io_1_wstrb = m_axi_io_1.wstrb;
assign m_axi_io_1_wlast = m_axi_io_1.wlast;
assign m_axi_io_1.wready = m_axi_io_1_wready;
// B
// assign m_axi_io_1_bid = m_axi.bid;
assign m_axi_io_1.bvalid = m_axi_io_1_bvalid;
assign m_axi_io_1.bresp = m_axi_io_1_bresp;
assign m_axi_io_1_bready = m_axi_io_1.bready;

/*
 * AXI ACP #0
 */
axi_write_address_channel #(
	.AXI_AWADDR_WIDTH(C_M_AXI_ACP_ADDR_WIDTH)
) m_axi_acp_0_aw();
axi_write_channel #(
	.AXI_WDATA_WIDTH(C_M_AXI_ACP_DATA_WIDTH)
) m_axi_acp_0_w();
axi_write_response_channel m_axi_acp_0_b();
axi_read_address_channel #(
	.AXI_ARADDR_WIDTH(C_M_AXI_ACP_ADDR_WIDTH)
) m_axi_acp_0_ar();
axi_read_channel #(
	.AXI_RDATA_WIDTH(C_M_AXI_ACP_DATA_WIDTH)
) m_axi_acp_0_r();

// AR
// assign m_axi_arid = m_axi.arid;
assign m_axi_acp_0_arvalid = m_axi_acp_0_ar.arvalid;
assign m_axi_acp_0_araddr = m_axi_acp_0_ar.araddr;
assign m_axi_acp_0_arlen = m_axi_acp_0_ar.arlen;
assign m_axi_acp_0_aruser = m_axi_acp_0_ar.aruser;
assign m_axi_acp_0_arqos = m_axi_acp_0_ar.arqos;
assign m_axi_acp_0_arprot = m_axi_acp_0_ar.arprot;
assign m_axi_acp_0_arsize = m_axi_acp_0_ar.arsize;
assign m_axi_acp_0_arburst = m_axi_acp_0_ar.arburst;
assign m_axi_acp_0_arcache = m_axi_acp_0_ar.arcache;
assign m_axi_acp_0_ar.arready = m_axi_acp_0_arready;
// R
// assign m_axi_acp_0_rid = m_axi.rid;
assign m_axi_acp_0_r.rvalid = m_axi_acp_0_rvalid;
assign m_axi_acp_0_r.rdata = m_axi_acp_0_rdata;
assign m_axi_acp_0_r.rresp = m_axi_acp_0_rresp;
assign m_axi_acp_0_r.rlast = m_axi_acp_0_rlast;
assign m_axi_acp_0_rready = m_axi_acp_0_r.rready;
// AW
assign m_axi_acp_0_awvalid = m_axi_acp_0_aw.awvalid;
assign m_axi_acp_0_awaddr = m_axi_acp_0_aw.awaddr;
assign m_axi_acp_0_awlen = m_axi_acp_0_aw.awlen;
assign m_axi_acp_0_awuser = m_axi_acp_0_aw.awuser;
assign m_axi_acp_0_awqos = m_axi_acp_0_aw.awqos;
assign m_axi_acp_0_awprot = m_axi_acp_0_aw.awprot;
assign m_axi_acp_0_awsize = m_axi_acp_0_aw.awsize;
assign m_axi_acp_0_awburst = m_axi_acp_0_aw.awburst;
assign m_axi_acp_0_awcache = m_axi_acp_0_aw.awcache;
assign m_axi_acp_0_aw.awready = m_axi_acp_0_awready;
// W
assign m_axi_acp_0_wvalid = m_axi_acp_0_w.wvalid;
assign m_axi_acp_0_wdata = m_axi_acp_0_w.wdata;
assign m_axi_acp_0_wstrb = m_axi_acp_0_w.wstrb;
assign m_axi_acp_0_wlast = m_axi_acp_0_w.wlast;
assign m_axi_acp_0_w.wready = m_axi_acp_0_wready;
// B
// assign m_axi_acp_0_bid = m_axi.bid;
assign m_axi_acp_0_b.bvalid = m_axi_acp_0_bvalid;
assign m_axi_acp_0_b.bresp = m_axi_acp_0_bresp;
assign m_axi_acp_0_bready = m_axi_acp_0_b.bready;

/*
 * AXI ACP #1
 */
axi_write_address_channel #(
	.AXI_AWADDR_WIDTH(C_M_AXI_ACP_ADDR_WIDTH)
) m_axi_acp_1_aw();
axi_write_channel #(
	.AXI_WDATA_WIDTH(C_M_AXI_ACP_DATA_WIDTH)
) m_axi_acp_1_w();
axi_write_response_channel m_axi_acp_1_b();

axi_read_address_channel #(
	.AXI_ARADDR_WIDTH(C_M_AXI_ACP_ADDR_WIDTH)
) m_axi_acp_1_ar();
axi_read_channel #(
	.AXI_RDATA_WIDTH(C_M_AXI_ACP_DATA_WIDTH)
) m_axi_acp_1_r();

// AR
// assign m_axi_arid = m_axi.arid;
assign m_axi_acp_1_arvalid = m_axi_acp_1_ar.arvalid;
assign m_axi_acp_1_araddr = m_axi_acp_1_ar.araddr;
assign m_axi_acp_1_arlen = m_axi_acp_1_ar.arlen;
assign m_axi_acp_1_aruser = m_axi_acp_1_ar.aruser;
assign m_axi_acp_1_arqos = m_axi_acp_1_ar.arqos;
assign m_axi_acp_1_arprot = m_axi_acp_1_ar.arprot;
assign m_axi_acp_1_arsize = m_axi_acp_1_ar.arsize;
assign m_axi_acp_1_arburst = m_axi_acp_1_ar.arburst;
assign m_axi_acp_1_arcache = m_axi_acp_1_ar.arcache;
assign m_axi_acp_1_ar.arready = m_axi_acp_1_arready;
// R
// assign m_axi_acp_1_rid = m_axi.rid;
assign m_axi_acp_1_r.rvalid = m_axi_acp_1_rvalid;
assign m_axi_acp_1_r.rdata = m_axi_acp_1_rdata;
assign m_axi_acp_1_r.rresp = m_axi_acp_1_rresp;
assign m_axi_acp_1_r.rlast = m_axi_acp_1_rlast;
assign m_axi_acp_1_rready = m_axi_acp_1_r.rready;
// AW
assign m_axi_acp_1_awvalid = m_axi_acp_1_aw.awvalid;
assign m_axi_acp_1_awaddr = m_axi_acp_1_aw.awaddr;
assign m_axi_acp_1_awlen = m_axi_acp_1_aw.awlen;
assign m_axi_acp_1_awuser = m_axi_acp_1_aw.awuser;
assign m_axi_acp_1_awqos = m_axi_acp_1_aw.awqos;
assign m_axi_acp_1_awprot = m_axi_acp_1_aw.awprot;
assign m_axi_acp_1_awsize = m_axi_acp_1_aw.awsize;
assign m_axi_acp_1_awburst = m_axi_acp_1_aw.awburst;
assign m_axi_acp_1_awcache = m_axi_acp_1_aw.awcache;
assign m_axi_acp_1_aw.awready = m_axi_acp_1_awready;
// W
assign m_axi_acp_1_wvalid = m_axi_acp_1_w.wvalid;
assign m_axi_acp_1_wdata = m_axi_acp_1_w.wdata;
assign m_axi_acp_1_wstrb = m_axi_acp_1_w.wstrb;
assign m_axi_acp_1_wlast = m_axi_acp_1_w.wlast;
assign m_axi_acp_1_w.wready = m_axi_acp_1_wready;
// B
// assign m_axi_acp_1_bid = m_axi.bid;
assign m_axi_acp_1_b.bvalid = m_axi_acp_1_bvalid;
assign m_axi_acp_1_b.bresp = m_axi_acp_1_bresp;
assign m_axi_acp_1_bready = m_axi_acp_1_b.bready;

/*
 * AXI DMA
 */
axi_write_address_channel m_axi_dma_aw();
axi_write_channel #(
	.AXI_WDATA_WIDTH(C_M_AXI_DMA_DATA_WIDTH)
) m_axi_dma_w();
axi_write_response_channel m_axi_dma_b();

axi_read_address_channel m_axi_dma_ar();
axi_read_channel #(
	.AXI_RDATA_WIDTH(C_M_AXI_DMA_DATA_WIDTH)
) m_axi_dma_r();

// AR
// assign m_axi_arid = m_axi.arid;
assign m_axi_dma_arvalid = m_axi_dma_ar.arvalid;
assign m_axi_dma_araddr = m_axi_dma_ar.araddr;
assign m_axi_dma_arlen = m_axi_dma_ar.arlen;
assign m_axi_dma_arsize = m_axi_dma_ar.arsize;
assign m_axi_dma_arburst = m_axi_dma_ar.arburst;
assign m_axi_dma_arcache = m_axi_dma_ar.arcache;
assign m_axi_dma_ar.arready = m_axi_dma_arready;
// R
// assign m_axi_dma_rid = m_axi.rid;
assign m_axi_dma_r.rvalid = m_axi_dma_rvalid;
assign m_axi_dma_r.rdata = m_axi_dma_rdata;
assign m_axi_dma_r.rresp = m_axi_dma_rresp;
assign m_axi_dma_r.rlast = m_axi_dma_rlast;
assign m_axi_dma_rready = m_axi_dma_r.rready;
// AW
assign m_axi_dma_awvalid = m_axi_dma_aw.awvalid;
assign m_axi_dma_awaddr = m_axi_dma_aw.awaddr;
assign m_axi_dma_awlen = m_axi_dma_aw.awlen;
assign m_axi_dma_awsize = m_axi_dma_aw.awsize;
assign m_axi_dma_awburst = m_axi_dma_aw.awburst;
assign m_axi_dma_awcache = m_axi_dma_aw.awcache;
assign m_axi_dma_aw.awready = m_axi_dma_awready;
// W
assign m_axi_dma_wvalid = m_axi_dma_w.wvalid;
assign m_axi_dma_wdata = m_axi_dma_w.wdata;
assign m_axi_dma_wstrb = m_axi_dma_w.wstrb;
assign m_axi_dma_wlast = m_axi_dma_w.wlast;
assign m_axi_dma_w.wready = m_axi_dma_wready;
// B
// assign m_axi_dma_bid = m_axi.bid;
assign m_axi_dma_b.bvalid = m_axi_dma_bvalid;
assign m_axi_dma_b.bresp = m_axi_dma_bresp;
assign m_axi_dma_bready = m_axi_dma_b.bready;

/*
 * GEM
 */
gem_tx_interface gem_tx();
assign gem_tx.tx_clock = gem_tx_clock;
assign gem_tx.tx_resetn = gem_tx_resetn;
assign gem_tx_r_data_rdy = gem_tx.tx_r_data_rdy;
assign gem_tx.tx_r_rd = gem_tx_r_rd;
assign gem_tx_r_valid = gem_tx.tx_r_valid;
assign gem_tx_r_data = gem_tx.tx_r_data;
assign gem_tx_r_sop = gem_tx.tx_r_sop;
assign gem_tx_r_eop = gem_tx.tx_r_eop;
assign gem_tx_r_err = gem_tx.tx_r_err;
assign gem_tx_r_underflow = gem_tx.tx_r_underflow;
assign gem_tx_r_flushed = gem_tx.tx_r_flushed;
assign gem_tx_r_control = gem_tx.tx_r_control;
assign gem_tx.tx_r_status = gem_tx_r_status;
assign gem_tx.tx_r_fixed_lat = gem_tx_r_fixed_lat;
assign gem_tx.dma_tx_end_tog = gem_dma_tx_end_tog;
assign gem_dma_tx_status_tog = gem_tx.dma_tx_status_tog;

gem_rx_interface gem_rx();
assign gem_rx.rx_clock = gem_rx_clock;
assign gem_rx.rx_resetn = gem_rx_resetn;
assign gem_rx.rx_w_wr = gem_rx_w_wr;
assign gem_rx.rx_w_data = gem_rx_w_data;
assign gem_rx.rx_w_sop = gem_rx_w_sop;
assign gem_rx.rx_w_eop = gem_rx_w_eop;
assign gem_rx.rx_w_status = gem_rx_w_status;
assign gem_rx.rx_w_err = gem_rx_w_err;
assign gem_rx_w_overflow = gem_rx.rx_w_overflow;
assign gem_rx.rx_w_flush = gem_rx_w_flush;

wire logic gem_irq_tx_core;
wire logic gem_irq_rx_core;
assign gem_irq = gem_irq_rx_core | gem_irq_tx_core;

prism_sp_duo_tx_top #(
	.IBRAM_SIZE(IBRAM_SIZE),
	.DBRAM_SIZE(DBRAM_SIZE),
	.ACPBRAM_SIZE(ACPBRAM_SIZE),
	.TX_DATA_FIFO_SIZE(TX_DATA_FIFO_SIZE),
	.TX_DATA_FIFO_WIDTH(C_M_AXI_DMA_DATA_WIDTH)
) prism_sp_duo_tx_top_0 (
	.clock(clock),
	.resetn(resetn),

	.gem_irq(gem_irq_tx_core),
	.gem_irq_tx,

	.s_axil_aw(s_axil_0_aw),
	.s_axil_w(s_axil_0_w),
	.s_axil_b(s_axil_0_b),
	.s_axil_ar(s_axil_0_ar),
	.s_axil_r(s_axil_0_r),

	.m_axi_io(m_axi_io_0),

	.m_axi_acp_aw(m_axi_acp_0_aw),
	.m_axi_acp_w(m_axi_acp_0_w),
	.m_axi_acp_b(m_axi_acp_0_b),
	.m_axi_acp_ar(m_axi_acp_0_ar),
	.m_axi_acp_r(m_axi_acp_0_r),

	.m_axi_dma_ar,
	.m_axi_dma_r,

	.gem_tx(gem_tx)
);

prism_sp_duo_rx_top #(
	.IBRAM_SIZE(IBRAM_SIZE),
	.DBRAM_SIZE(DBRAM_SIZE),
	.ACPBRAM_SIZE(ACPBRAM_SIZE),
	.RX_DATA_FIFO_SIZE(RX_DATA_FIFO_SIZE),
	.RX_DATA_FIFO_WIDTH(C_M_AXI_DMA_DATA_WIDTH)
) prism_sp_duo_rx_top_0 (
	.clock(clock),
	.resetn(resetn),

	.gem_irq(gem_irq_rx_core),
	.gem_irq_rx,

	.s_axil_aw(s_axil_1_aw),
	.s_axil_w(s_axil_1_w),
	.s_axil_b(s_axil_1_b),
	.s_axil_ar(s_axil_1_ar),
	.s_axil_r(s_axil_1_r),

	.m_axi_io(m_axi_io_1),

	.m_axi_acp_aw(m_axi_acp_1_aw),
	.m_axi_acp_w(m_axi_acp_1_w),
	.m_axi_acp_b(m_axi_acp_1_b),
	.m_axi_acp_ar(m_axi_acp_1_ar),
	.m_axi_acp_r(m_axi_acp_1_r),

	.m_axi_dma_aw,
	.m_axi_dma_w,
	.m_axi_dma_b,

	.gem_rx(gem_rx)
);

endmodule
