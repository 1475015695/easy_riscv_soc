#ifndef __INTERRUPT_H
#define __INTERRUPT_H
#define mstatus 0x300
#define misa 0x301
#define medeleg 0x302
#define mideleg 0x303
#define mie 0x304
#define mtvec 0x305
#define mcounteren 0x306
#define mscratch 0x340
#define mepc 0x341
#define mcause 0x342
#define mtval 0x343
#define mip 0x344

#define timer_csr1_address 30716
#define timer_csr2_address 30712

#define csr_write(csr_address,csr_write_data) asm volatile ("csrrw x0,"#csr_address", %0" ::"r"(csr_write_data));
#define csr_read(csr_address) ({ uint __tmp; \
  asm volatile ("csrr %0," #csr_address  : "=r"(__tmp)); \
  __tmp; })



#endif

