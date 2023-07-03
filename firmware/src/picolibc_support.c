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
#include <stdint.h>

#include "uart.h"

int
serial_putc(char c, FILE *file)
{
	serial_putc_stdout(c);
	return 0;
}

int
serial_getc(FILE *file)
{
	// XXX Not implemented.
	return '?';
}

FILE __stdio = FDEV_SETUP_STREAM(serial_putc, serial_getc, NULL, _FDEV_SETUP_RW);
// stdin, stdout and stderr are all stdio.
FILE * const stdin = &__stdio;
__strong_reference(stdin, stdout);
__strong_reference(stdin, stderr);
#if 0
// This became obsolete with commit 1eba3461fd1664d38be36f3bf21898f889a7d2e3
// in picolibc.
// Keep it around until we're absolutely sure that nobody uses the old tool
// chain anymore.
FILE *const __iob[3] = { &__stdio, &__stdio, &__stdio };
#endif
