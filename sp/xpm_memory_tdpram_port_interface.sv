/*
 * Copyright (c) 2023 Robert Drehmel
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
interface xpm_memory_tdpram_port_interface
#(
	parameter int ADDR_WIDTH,
	parameter int DATA_WIDTH
);

localparam int STROBE_WIDTH = DATA_WIDTH / 8;

logic clk;
logic rst;
logic [ADDR_WIDTH-1:0] addr;
logic [DATA_WIDTH-1:0] din;
logic [DATA_WIDTH-1:0] dout;
logic en;
logic [STROBE_WIDTH-1:0] we;

modport master (
	input clk,
	input rst,
	output addr,
	output din,
	input dout,
	output en,
	output we
);

modport slave (
	input clk,
	input rst,
	input addr,
	input din,
	output dout,
	input en,
	input we
);
endinterface
