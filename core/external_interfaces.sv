/*
 * Modifications:
 * Copyright (c) 2021-2023 Robert Drehmel
 *
 * Initial implementation:
 * Copyright © 2019 Eric Matthews,  Lesley Shannon
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
import taiga_types::*;
import l2_config_and_types::*;

interface axi_interface
#(
	parameter int C_M_AXI_ADDR_WIDTH,
	parameter int C_M_AXI_DATA_WIDTH
);

    logic arready;
    logic arvalid;
    logic [C_M_AXI_ADDR_WIDTH-1:0] araddr;
    logic [7:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arburst;
    logic [3:0] arcache;
    logic [2:0] arprot;
    logic [5:0] arid;
	logic arlock;

    //read data
    logic rready;
    logic rvalid;
    logic [C_M_AXI_DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rlast;
    logic [5:0] rid;

    //Write channel
    //write address
    logic awready;
    logic awvalid;
    logic [C_M_AXI_ADDR_WIDTH-1:0] awaddr;
    logic [7:0] awlen;
    logic [2:0] awsize;
    logic [1:0] awburst;
    logic [3:0] awcache;
    logic [2:0] awprot;
    logic [5:0] awid;
	logic awlock;

    //write data
    logic wready;
    logic wvalid;
    logic [C_M_AXI_DATA_WIDTH-1:0] wdata;
    logic [(C_M_AXI_DATA_WIDTH/8)-1:0] wstrb;
    logic wlast;

    //write response
    logic bready;
    logic bvalid;
    logic [1:0] bresp;
    logic [5:0] bid;

    modport master (input arready, rvalid, rdata, rresp, rlast, rid, awready, wready, bvalid, bresp, bid,
            output arvalid, araddr, arlen, arsize, arburst, arcache, arprot, arid, arlock, rready, awvalid, awaddr, awlen, awsize, awburst, awcache, awprot, awid, awlock,
            wvalid, wdata, wstrb, wlast, bready);


    modport slave (input arvalid, araddr, arlen, arsize, arburst, arcache, arprot,
            rready,
            awvalid, awaddr, awlen, awsize, awburst, awcache, awprot, arid,
            wvalid, wdata, wstrb, wlast, awid,
            bready,
            output arready, rvalid, rdata, rresp, rlast, rid,
            awready,
            wready,
            bvalid, bresp, bid);

endinterface

interface l1_arbiter_request_interface;
    logic [31:0] addr;
    logic [31:0] data ;
    logic rnw ;
    logic [3:0] be;
    logic [4:0] size;
    logic is_amo;
    logic [4:0] amo;

    logic request;
    logic ack;

    function  l2_request_t to_l2 (input bit[L2_SUB_ID_W-1:0] sub_id);
        to_l2.addr = addr[31:2];
        to_l2.rnw = rnw;
        to_l2.be = be;
        to_l2.is_amo = is_amo;
        to_l2.amo_type_or_burst_size = is_amo ? amo : size;
        to_l2.sub_id = sub_id;
    endfunction

    modport master (output addr, data, rnw, be, size, is_amo, amo, request, input ack);
    modport slave (import to_l2, input addr, data, rnw, be, size, is_amo, amo, request, output ack);

endinterface

interface l1_arbiter_return_interface;
    logic [31:2] inv_addr;
    logic inv_valid;
    logic inv_ack;
    logic [31:0] data;
    logic data_valid;

    modport master (input inv_addr, inv_valid, data, data_valid, output inv_ack);
    modport slave (output inv_addr, inv_valid, data, data_valid, input inv_ack);

endinterface

