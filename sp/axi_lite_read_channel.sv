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
interface axi_lite_read_channel
#(
	parameter integer AXI_RDATA_WIDTH = 32
)
();
logic rvalid;
logic rready;
logic [AXI_RDATA_WIDTH-1:0] rdata;
logic [1:0] rresp;

modport master(
	input rvalid,
	output rready,
	input rdata,
	input rresp
);
modport slave(
	output rvalid,
	input rready,
	output rdata,
	output rresp
);
endinterface
