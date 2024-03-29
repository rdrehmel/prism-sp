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
interface axi_lite_read_address_channel
#(
	parameter integer AXI_ARADDR_WIDTH = 8
)
();
logic arvalid;
logic arready;
logic [AXI_ARADDR_WIDTH-1 : 0] araddr;
logic [2:0] arprot;

modport master(
	output arvalid,
	input arready,
	output araddr,
	output arprot
);
modport slave(
	input arvalid,
	output arready,
	input araddr,
	input arprot
);
endinterface
