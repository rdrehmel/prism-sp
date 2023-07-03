/*
 * Copyright (c) 2021-2023 Robert Drehmel
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
interface gem_rx_interface;
	logic rx_clock;
	logic rx_resetn;
	logic rx_w_wr;
	logic [31:0] rx_w_data;
	logic rx_w_sop;
	logic rx_w_eop;
	logic [44:0] rx_w_status;
	logic rx_w_err;
	logic rx_w_overflow;
	logic rx_w_flush;

	modport slave(
		input rx_clock,
		input rx_resetn,
		input rx_w_wr,
		input rx_w_data,
		input rx_w_sop,
		input rx_w_eop,
		input rx_w_status,
		input rx_w_err,
		output rx_w_overflow,
		input rx_w_flush
	);
endinterface
