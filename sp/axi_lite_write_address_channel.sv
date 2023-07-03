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
interface axi_lite_write_address_channel
#(
	parameter integer AXI_AWADDR_WIDTH = 8
)
();
logic awvalid;
logic awready;
logic [AXI_AWADDR_WIDTH-1 : 0] awaddr;
logic [2:0] awprot;

modport master (
	output awvalid,
	input awready,
	output awaddr,
	output awprot
);
modport slave (
	input awvalid,
	output awready,
	input awaddr,
	input awprot
);
endinterface
