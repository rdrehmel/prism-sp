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
interface gem_tx_interface;
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

	modport master(
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
		output dma_tx_status_tog
	);
endinterface
