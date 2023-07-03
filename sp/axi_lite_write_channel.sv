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
interface axi_lite_write_channel
#(
	parameter integer AXI_WDATA_WIDTH = 32
)
();
logic wvalid;
logic wready;
logic [AXI_WDATA_WIDTH-1 : 0] wdata;
logic [(AXI_WDATA_WIDTH/8)-1 : 0] wstrb;

modport master (
	output wvalid,
	input wready,
	output wdata,
	output wstrb
);
modport slave (
	input wvalid,
	output wready,
	input wdata,
	input wstrb
);
endinterface
