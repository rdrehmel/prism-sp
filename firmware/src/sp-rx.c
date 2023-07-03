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
#include <stdio.h>

#include "sp.h"

struct sp_config rx_config;

void
load_rx_config()
{
	rx_config.data_fifo_size = sp_load_reg(SP_REGN_RX_DATA_FIFO_SIZE);
	rx_config.data_fifo_width = sp_load_reg(SP_REGN_RX_DATA_FIFO_WIDTH);
	printf("RX data FIFO:\n");
	printf("  Width: %10d\n", rx_config.data_fifo_width);
	printf("  Size : %10d\n", rx_config.data_fifo_size);
}
