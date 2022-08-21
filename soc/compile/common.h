#ifndef __COMMON_H
#define __COMMON_H
#define uint unsigned int
#define uchar unsigned char

#define timer_csr_address 0x90000000
#define timer_count_address 0x90000001
#define gpio_csr_address 0xa0000000
#define gpio_port_address 0xa0000001
#define uart_csr_address 0xb0000000
#define uart_buadrate_address 0xb0000001
#define uart_tx_data_address 0xb0000002
#define uart_rx_data_address 0xb0000003
#define uart_tx_enable 0
#define uart_rx_enable 1
#define uart_txing 2
#define uart_rxing 3
#define uart_rx_interrupt_enable 4


// #define write_memory(address,val) asm volatile("li t0," #address "\r\n" "sw t0,0(%0)" ::"r"(val));
#define memory(addr) (*(( unsigned int *)addr))
#define write_memory(address,val) asm volatile("li t0," #address "\r\n" "sw %0,0(t0)" ::"r"(val));
#define read_memory(address) ({int temp;\
asm volatile(\
    "li t0,"#address" \r\n"\
    "lw %0,0(t0)":"=r"(temp) :);\
temp;})


#endif