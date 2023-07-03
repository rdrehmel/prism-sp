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
interface acpram_axi_interface
#(
	parameter int ACPRAM_ADDR_WIDTH,
	parameter int AXI_ADDR_WIDTH
);

logic read;
logic write;
logic [ACPRAM_ADDR_WIDTH-1:0] acpram_addr;
logic [AXI_ADDR_WIDTH-1:0] axi_addr;
logic len;

logic done;
logic error;
logic busy;

modport master (
	output read,
	output write,
	output acpram_addr,
	output axi_addr,
	output len,
	input done,
	input error,
	input busy
);

modport slave (
	input read,
	input write,
	input acpram_addr,
	input axi_addr,
	input len,
	output done,
	output error,
	output busy
);
endinterface
