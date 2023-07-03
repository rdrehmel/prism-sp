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
#ifndef _CSR_H_
#define _CSR_H_

static inline uint64_t csr_read_cycle()
{
	// Modelled after the code in
	// "RISC-V Instruction Set Manual, Volume I: RISC-V User-Level ISA, 20191214"
	// "10.1 Base Counters and Timers"
	uint32_t x, y, z;
	asm volatile (
		"csr_read_cycle_again_%=:\n"
		"		rdcycleh	%0\n"
		"		rdcycle		%1\n"
		"		rdcycleh	%2\n"
		"       bne			%0, %2, csr_read_cycle_again_%=\n" 
		: "=r" (x), "=r" (y), "=r" (z)
		: 
		: 
	);
	return (uint64_t)x << 32 | y;
}

static inline uint64_t csr_read_time()
{
	// Modelled after the code in
	// "RISC-V Instruction Set Manual, Volume I: RISC-V User-Level ISA, 20191214"
	// "10.1 Base Counters and Timers"
	uint32_t x, y, z;
	asm volatile (
		"csr_read_time_again_%=:\n"
		"		rdtimeh		%0\n"
		"		rdtime		%1\n"
		"		rdtimeh		%2\n"
		"       bne			%0, %2, csr_read_time_again_%=\n" 
		: "=r" (x), "=r" (y), "=r" (z)
		: 
		: 
	);
	return (uint64_t)x << 32 | y;
}

static inline uint64_t csr_read_instret()
{
	// Modelled after the code in
	// "RISC-V Instruction Set Manual, Volume I: RISC-V User-Level ISA, 20191214"
	// "10.1 Base Counters and Timers"
	uint32_t x, y, z;
	asm volatile (
		"csr_read_instret_again_%=:\n"
		"		rdinstret		%0\n"
		"		rdinstret		%1\n"
		"		rdinstret		%2\n"
		"       bne			%0, %2, csr_read_instret_again_%=\n" 
		: "=r" (x), "=r" (y), "=r" (z)
		: 
		: 
	);
	return (uint64_t)x << 32 | y;
}

#endif
