/*
 * Copyright (c) 2016 Robert Drehmel
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
interface axi_write_address_channel
#(
	parameter integer AXI_AWID_WIDTH = 1,
	parameter integer AXI_AWADDR_WIDTH = 32,
	parameter integer AXI_AWUSER_WIDTH = 0
)
();
logic [AXI_AWID_WIDTH-1:0] awid;
logic [AXI_AWADDR_WIDTH-1:0] awaddr;
logic [7:0] awlen;
logic [2:0] awsize;
logic [1:0] awburst;
logic awlock;
logic [3:0] awcache;
logic [2:0] awprot;
logic [3:0] awqos;
logic [3:0] awregion;
logic [AXI_AWUSER_WIDTH-1:0] awuser;
logic awvalid;
logic awready;

modport master (
	output awid,
	output awaddr,
	output awlen,
	output awsize,
	output awburst,
	output awlock,
	output awcache,
	output awprot,
	output awqos,
	output awregion,
	output awuser,
	output awvalid,
	input awready
);
modport slave (
	input awid,
	input awaddr,
	input awlen,
	input awsize,
	input awburst,
	input awlock,
	input awcache,
	input awprot,
	input awqos,
	input awregion,
	input awuser,
	input awvalid,
	output awready
);

modport monitor (
	input awid,
	input awaddr,
	input awlen,
	input awsize,
	input awburst,
	input awlock,
	input awcache,
	input awprot,
	input awqos,
	input awregion,
	input awuser,
	input awvalid,
	input awready
);

endinterface
