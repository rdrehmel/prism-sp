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
interface memory_read_interface #(
	parameter integer ADDR_WIDTH = 32,
	parameter integer DATA_WIDTH = 32,
	parameter integer LEN_WIDTH = 16
);

logic [ADDR_WIDTH-1:0] addr;
logic [LEN_WIDTH-1:0] len;

// Asserted to request a new memory transfer.
logic start;
// Asserted along with 'start' to merge the extra bytes with the first
// bytes of the next transfer.
logic cont;
// Asserted while no new request can be accepted.
logic busy;
// Asserted when read transaction is complete.
logic done;
// Asserted when an error was encountered.
// Only valid while 'done' is also asserted.
logic error;

modport master (
	output addr,
	output len,
	output start,
	output cont,
	input busy,
	input done,
	input error
);
modport slave (
	input addr,
	input len,
	input start,
	input cont,
	output busy,
	output done,
	output error
);

endinterface
