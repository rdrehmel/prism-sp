CC=riscv32-unknown-elf-gcc
OBJCOPY=riscv32-unknown-elf-objcopy

STACK_SIZE=$$((4*1024))

# Use this for a single BRAM
# no special linker script is needed.
#BRAM_ADDR=0x00020000
#BRAM_SIZE=$$((64*1024))
#CFLAGS=-Xlinker --defsym=__mem_addr=$(BRAM_ADDR) \
#	-Xlinker --defsym=__mem_size=$(BRAM_SIZE)

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
	-T separate-brams.ld

CFLAGS+=-Xlinker --defsym=__stack_size=$(STACK_SIZE) \
	--specs=picolibc.specs \
	-march=rv32im \
	-mabi=ilp32

LDFLAGS=-Wl,--print-memory-usage

TARGET=firmware
HEADERS:=sp.h uart.h gem.h
SRCS:=main.c uart.c picolibc_support.c
OBJDIR:=obj
OBJS:=$(SRCS:%.c=$(OBJDIR)/%.o)

all: $(OBJDIR) $(TARGET).bin

$(OBJDIR): ;
	@mkdir $(OBJDIR)

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).elf: $(OBJS)
	$(CC) -o $@ $(CFLAGS) $(LDFLAGS) $(OBJS)
	
$(OBJDIR)/%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(OBJDIR) $(TARGET) $(TARGET).*
