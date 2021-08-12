/*
 * Copyright (c) 2021 Robert Drehmel
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
interface memory_write_interface #(
	parameter integer ADDR_WIDTH = 32,
	parameter integer DATA_WIDTH = 32,
	parameter integer LEN_WIDTH = 16
);

logic [ADDR_WIDTH-1:0] addr;
logic [LEN_WIDTH-1:0] len;

// Start AXI write.
logic start;
// Asserted while write transaction is pending.
logic busy;
// Asserted when write transaction is complete.
logic done;
// Asserted when ERROR is detected.
// Only valid when 'done' is asserted.
logic error;

modport master (
	output addr,
	output len,
	output start,
	input busy,
	input done,
	input error
);
modport slave (
	input addr,
	input len,
	input start,
	output busy,
	output done,
	output error
);
endinterface
