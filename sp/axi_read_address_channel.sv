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
interface axi_read_address_channel
#(
	parameter integer AXI_ARID_WIDTH = 1,
	parameter integer AXI_ARADDR_WIDTH = 32,
	parameter integer AXI_ARUSER_WIDTH = 0
)
();
logic [AXI_ARID_WIDTH-1 : 0] arid;
logic [AXI_ARADDR_WIDTH-1 : 0] araddr;
logic [7:0] arlen;
logic [2:0] arsize;
logic [1:0] arburst;
logic arlock;
logic [3:0] arcache;
logic [2:0] arprot;
logic [3:0] arqos;
logic [3:0] arregion;
logic [AXI_ARUSER_WIDTH-1 : 0] aruser;
logic arvalid;
logic arready;

modport master(
	output arid,
	output araddr,
	output arlen,
	output arsize,
	output arburst,
	output arlock,
	output arcache,
	output arprot,
	output arqos,
	output arregion,
	output aruser,
	output arvalid,
	input arready
);
modport slave(
	input arid,
	input araddr,
	input arlen,
	input arsize,
	input arburst,
	input arlock,
	input arcache,
	input arprot,
	input arqos,
	input arregion,
	input aruser,
	input arvalid,
	output arready
);

modport monitor(
	input arid,
	input araddr,
	input arlen,
	input arsize,
	input arburst,
	input arlock,
	input arcache,
	input arprot,
	input arqos,
	input arregion,
	input aruser,
	input arvalid,
	input arready
);
endinterface
