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
interface gem_interface;
	logic tx_clock;
	logic tx_resetn;
	logic tx_r_data_rdy;
	logic tx_r_rd;
	logic tx_r_valid;
	logic [7:0] tx_r_data;
	logic tx_r_sop;
	logic tx_r_eop;
	logic tx_r_err;
	logic tx_r_underflow;
	logic tx_r_flushed;
	logic tx_r_control;
	logic [3:0] tx_r_status;
	logic tx_r_fixed_lat;

	logic dma_tx_end_tog;
	logic dma_tx_status_tog;

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
		input tx_clock,
		input tx_resetn,
		output tx_r_data_rdy,
		input tx_r_rd,
		output tx_r_valid,
		output tx_r_data,
		output tx_r_sop,
		output tx_r_eop,
		output tx_r_err,
		output tx_r_underflow,
		output tx_r_flushed,
		output tx_r_control,
		input tx_r_status,
		input tx_r_fixed_lat,
		input dma_tx_end_tog,
		output dma_tx_status_tog,
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
