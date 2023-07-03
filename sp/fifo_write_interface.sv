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

interface fifo_write_interface #(
	parameter int DATA_WIDTH = 32
);

logic [DATA_WIDTH-1:0] wr_data;
logic wr_en;
logic full;
logic almost_full;

modport master(
	output wr_data,
	output wr_en,
	input full,
	input almost_full
);

modport slave(
	input wr_data,
	input wr_en,
	output full,
	output almost_full
);

modport monitor_out(
	output wr_data,
	output wr_en,
	output full,
	output almost_full
);

endinterface
