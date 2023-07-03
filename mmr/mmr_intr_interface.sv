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
interface mmr_intr_interface#(
	parameter int N,
	parameter int WIDTH
);

logic [WIDTH-1:0] imr [N];
logic [WIDTH-1:0] isr [N];
logic [WIDTH-1:0] isr_pulses [N];
logic [N-1:0] interrupts;

for (genvar i = 0; i < N; i++) begin
	assign interrupts[i] = |(isr[i] & imr[i]);
end

modport master(
	input imr,
	input isr,
	output isr_pulses,
	input interrupts
);
modport slave(
	output imr,
	output isr,
	input isr_pulses,
	output interrupts
);

endinterface

