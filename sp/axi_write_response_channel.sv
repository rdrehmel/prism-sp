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
interface axi_write_response_channel
#(
	parameter integer AXI_BID_WIDTH = 1,
	parameter integer AXI_BUSER_WIDTH = 0
)
();
logic [AXI_BID_WIDTH-1:0] bid;
logic [1:0] bresp;
logic [AXI_BUSER_WIDTH-1:0] buser;
logic bvalid;
logic bready;

modport master(
	input bid,
	input bresp,
	input buser,
	input bvalid,
	output bready
);
modport slave(
	output bid,
	output bresp,
	output buser,
	output bvalid,
	input bready
);
modport monitor(
	input bid,
	input bresp,
	input buser,
	input bvalid,
	input bready
);
endinterface
