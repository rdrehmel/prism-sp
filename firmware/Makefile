CC=riscv32-unknown-elf-gcc
OBJCOPY=riscv32-unknown-elf-objcopy

STACK_SIZE=$$((4*1024))

# Use this for two separate BRAMs
IBRAM_ADDR=0x00020000
IBRAM_SIZE=$$((32 * 1024))
DBRAM_SIZE=$$((32 * 1024))
DBRAM_ADDR_DEC=$$(($(IBRAM_ADDR) + $(IBRAM_SIZE)))
DBRAM_ADDR=$(shell printf 0x%08x $(DBRAM_ADDR_DEC))

CFLAGS=-Xlinker --defsym=__ibram_addr=$(IBRAM_ADDR) \
	-Xlinker --defsym=__dbram_addr=$(DBRAM_ADDR) \
	-Xlinker --defsym=__ibram_size=$(IBRAM_SIZE) \
	-Xlinker --defsym=__dbram_size=$(DBRAM_SIZE) \
	-Ofast \
	-T separate-brams.ld

CFLAGS+=-Xlinker --defsym=__stack_size=$(STACK_SIZE) \
	--specs=picolibc.specs \
	-march=rv32ima \
	-mabi=ilp32 \
	-D__freestanding__

LDFLAGS=-Wl,--print-memory-usage

#
# Targets and object directories
#
# desc
SP_DUO_RX_DESC_TARGET=prism-sp-duo-rx-firmware
SP_DUO_RX_DESC_OBJDIR=obj/sp-duo-rx
SP_DUO_TX_DESC_TARGET=prism-sp-duo-tx-firmware
SP_DUO_TX_DESC_OBJDIR=obj/sp-duo-tx

HEADERS:=src/sp.h \
	src/sp-desc.h \
	src/sp-desc-rx.h \
	src/sp-desc-tx.h \
	src/uart.h \
	src/uartlite.h \
	src/csr.h \
	src/mmio.h \
	src/gem.h \
	src/gem-dma.h

SP_DUO_RX_DESC_C_SRCS=src/sp-common.c \
	src/sp-duo-rx-desc.c \
	src/sp-rx.c \
	src/sp-desc-rx.c \
	src/uart.c \
	src/picolibc_support.c
SP_DUO_RX_DESC_OBJS=$(SP_DUO_RX_DESC_C_SRCS:src/%.c=$(SP_DUO_RX_DESC_OBJDIR)/%.o)

SP_DUO_TX_DESC_C_SRCS=src/sp-common.c \
	src/sp-duo-tx-desc.c \
	src/sp-tx.c \
	src/sp-desc-tx.c \
	src/uartlite.c \
	src/picolibc_support.c
SP_DUO_TX_DESC_OBJS=$(SP_DUO_TX_DESC_C_SRCS:src/%.c=$(SP_DUO_TX_DESC_OBJDIR)/%.o)

sp-duo: objdirs $(SP_DUO_RX_DESC_TARGET).elf $(SP_DUO_TX_DESC_TARGET).elf

.PHONY: objdirs
objdirs:
	@mkdir -p $(SP_DUO_RX_DESC_OBJDIR)
	@mkdir -p $(SP_DUO_TX_DESC_OBJDIR)

.PHONY: clean
clean:
	rm -rf obj/* *.elf

#
# Make flat binary files from ELF files
# SP desc
$(SP_DUO_RX_DESC_TARGET).bin: $(SP_DUO_RX_DESC_TARGET).elf
	$(OBJCOPY) -O binary $< $@
$(SP_DUO_TX_DESC_TARGET).bin: $(SP_DUO_TX_DESC_TARGET).elf
	$(OBJCOPY) -O binary $< $@

# Make ELF file from object files
# SP desc
$(SP_DUO_RX_DESC_TARGET).elf: $(SP_DUO_RX_DESC_OBJS)
	echo $(SP_DUO_RX_DESC_OBJS)
	$(CC) -o $@ $(CFLAGS) $(LDFLAGS) $^
$(SP_DUO_TX_DESC_TARGET).elf: $(SP_DUO_TX_DESC_OBJS)
	$(CC) -o $@ $(CFLAGS) $(LDFLAGS) $^

#
# Make object files
#
# sp-duo-rx
$(SP_DUO_RX_DESC_OBJDIR)/sp-common.o: src/sp-common.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_RX_DESC_OBJDIR)/sp-duo-rx-desc.o: src/sp-duo-rx-desc.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_RX_DESC_OBJDIR)/sp-rx.o: src/sp-rx.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_RX_DESC_OBJDIR)/sp-desc-rx.o: src/sp-desc-rx.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_RX_DESC_OBJDIR)/uart.o: src/uart.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_RX_DESC_OBJDIR)/picolibc_support.o: src/picolibc_support.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
# sp-duo-tx
$(SP_DUO_TX_DESC_OBJDIR)/sp-common.o: src/sp-common.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_TX_DESC_OBJDIR)/sp-duo-tx-desc.o: src/sp-duo-tx-desc.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_TX_DESC_OBJDIR)/sp-tx.o: src/sp-tx.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_TX_DESC_OBJDIR)/sp-desc-tx.o: src/sp-desc-tx.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_TX_DESC_OBJDIR)/uartlite.o: src/uartlite.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
$(SP_DUO_TX_DESC_OBJDIR)/picolibc_support.o: src/picolibc_support.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<
