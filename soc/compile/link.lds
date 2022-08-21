OUTPUT_ARCH( "riscv" )
ENTRY(_start)


/* MEMORY
{
  flash (wxa!ri) : ORIGIN = 0x00000000, LENGTH = 16K
  ram (wxa!ri) :   ORIGIN = 0x10000000, LENGTH = 16K
} */
/* 字符、等号间必须要有空格 */
MEMORY
{
  flash (wxa!ri) : ORIGIN = 0x0 , LENGTH = 32k
  ram (wxa!ri) : ORIGIN = 0x80000000 , LENGTH = 32k

}

SECTIONS
{
  
  
  . = 0x0;
  . = ALIGN(4);
  .text : 
  { 
    *(.text .text.*) 
  }>flash AT>flash

  
  .lalign         :
  {
    . = ALIGN(4);
    PROVIDE( data_start_bin = . );
  } >flash AT>flash 

  .dalign         :
  {
    . = ALIGN(4);
    PROVIDE( data_start_mem = . );
  } >ram AT>flash 

  /* PROVIDE要在ALIGN之后 */
  .data :
  {
      *(.data .data.*)
      *(.sdata .sdata.*)   
  }>ram AT>flash
  
  . = ALIGN(4);
  PROVIDE(data_end_mem = .);

  .bssalign :
  {
    . = ALIGN(4);
    PROVIDE(bss_start_mem = .);
  } >ram AT>ram
  .bss :
  {
      
      *(.bss .bss.*)
      *(.sbss .sbss.*)
      
  }>ram AT>ram
  PROVIDE(bss_end_mem = .);



/* 绝对地址偏移？ */
  /* .stack ORIGIN(ram) + LENGTH(ram) - __stack_size :
  {
    PROVIDE( _heap_end = . );
    . = __stack_size;
    PROVIDE( _sp = . );
    __freertos_irq_stack_top = .;
  } >ram AT>ram */
  .stack ORIGIN(ram) + LENGTH(ram) -2k :
  {
    PROVIDE( stack_end = . );
    . = 2k;
    PROVIDE( stack_start = . );
  } 
  /* .=ALIGN(4); */
  /* PROVIDE( stack_end = . )
  . = 0x8000 ;
  PROVIDE( stack_start = .) */

}