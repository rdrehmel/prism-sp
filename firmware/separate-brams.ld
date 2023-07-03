/*
 * Derived from picolibc.ld
 */
OUTPUT_ARCH( "riscv" )

ENTRY(_start)

MEMORY
{
  ibram : ORIGIN = __ibram_addr, LENGTH = __ibram_size
  dbram : ORIGIN = __dbram_addr, LENGTH = __dbram_size
}

SECTIONS
{
  PROVIDE(__stack = ORIGIN(dbram) + LENGTH(dbram));
  
  .init :
  {
    KEEP (*(.text.init.enter)) /*picolibc start*/
    KEEP (*(SORT_NONE(.init)))
  }> ibram

  .text :
  {
    *(.text.unlikely .text.unlikely.*)
    *(.text.startup .text.startup.*)
    *(.text .text.*)
    *(.gnu.linkonce.t.*)
  } > ibram

  .fini :
  {
    KEEP (*(SORT_NONE(.fini)))
  } > ibram

  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);

  . = ALIGN(4);

  .preinit_array :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } > ibram

  .init_array :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
    PROVIDE_HIDDEN (__init_array_end = .);
  } > ibram

  .fini_array     :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } > ibram

  .ctors :
  {
		KEEP (*crtbegin.o(.ctors))
		KEEP (*crtbegin?.o(.ctors))
		KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
		KEEP (*(SORT_BY_INIT_PRIORITY(.ctors.*)))
		KEEP (*(.ctors))
  } > ibram

  .dtors :
  {
		KEEP (*crtbegin.o(.dtors))
		KEEP (*crtbegin?.o(.dtors))
		KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
		KEEP (*(SORT_BY_INIT_PRIORITY(.dtors.*)))
		KEEP (*(.dtors))
  } > ibram

  .data :
  {
    *(.rdata)
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
    . = ALIGN(8);
    *(.srodata.cst16)
    *(.srodata.cst8)
    *(.srodata.cst4)
    *(.srodata.cst2)
    *(.srodata .srodata.*)
    *(.data.rel.ro .data.rel.ro.*)
    *(.got .got.*)
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    . = ALIGN(8);
    PROVIDE( __global_pointer$ = . + 0x800 );
    *(.sdata .sdata.* .sdata2.*)
    *(.gnu.linkonce.s.*)
  } >dbram

  /*for picolibc data init (no need to copy)*/
  PROVIDE( __data_source = 0 );
  PROVIDE( __data_start = 0 );
  PROVIDE( __data_end = 0 );
  PROVIDE( __data_size = 0 );

  .tdata :
  {
    PROVIDE( __tls_base = .);
    _tls_data = .;
    *(.tdata)
    *(.tdata.*)
    *(.gnu.linkonce.td*)
  } >dbram

  . = ALIGN(4);
  PROVIDE( __edata = . );
  PROVIDE( _edata = . );
  PROVIDE( edata = . );

  .tbss :
  {
  	PROVIDE( __bss_start = . );
    *(.tbss)
    *(.tbss.*)
    *(.gnu.linkonce.tb.*)
    *(.tcommon)
  } >dbram
	
  .bss :
  {
    *(.sbss*)
    *(.gnu.linkonce.sb.*)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(8);
	__bss_end = .;
  } >dbram
  PROVIDE( __bss_size = __bss_end - __bss_start );

  PROVIDE( __end = __bss_end );
  PROVIDE( _end = __bss_end );
  PROVIDE( end = __bss_end );

  PROVIDE( __heap_start = __end );
  PROVIDE( __heap_end = __stack - (DEFINED(__stack_size) ? __stack_size : 0x800)  );
  PROVIDE( __heap_size = __heap_end - __heap_start );
	
  /DISCARD/ : 
  {
	 *(.eh_frame .eh_frame.*)
    *(.note .note.*)
  }
}
