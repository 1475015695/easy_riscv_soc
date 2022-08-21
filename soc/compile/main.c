#include "interrupt.h"
#include "common.h"
extern void interrupt_entry();
uint timer_count=0;
int led=0;
int uart_ok=0;
int test=0;
uint interrupt_cause=0;
uint rx_data=0;
uint send_enable=0;
void interrupt_deal()
{
    interrupt_cause=csr_read(mcause);
    if(interrupt_cause&(1<<7))//timer
    {
        timer_count++;
        if(timer_count==16)
        {
            timer_count=0;
        } 
    }  
    else if(interrupt_cause&(1<<16))//uart rx
    {
        send_enable=1;
        memory(uart_tx_data_address)=memory(uart_rx_data_address);
    }

}
void interrupt_init()
{
    uint entery_address=interrupt_entry;//不能直接左移，语法不通过
    entery_address=entery_address<<2|0x0;//直接方式，所有中断都跳到这里来
    csr_write(mtvec,entery_address);//写中断入口地址
    uint mstatus_data=(1<<3)|(1<<7)|(1<<11)|(1<<12);//mie=1,mpie=1,mpp=11
    csr_write(mstatus,mstatus_data);
    csr_write(mie,(1<<7));//开启定时器中断 

 
    //timer init
    
    write_memory(0x90000001,50000000);//5*10^7     1*10^9/
    write_memory(0x90000000,1);//先写计数个数再使能，不然立即触发中断（计数值和目标值初始值都为零）

}
void delay(uint t)
{
    while(t--)
    {}
}
int main()
{
    int a=0; 
    int b=0;
    memory(gpio_csr_address)=0xffffffff;
    // write_memory(0xa0000000,0xffffffff);//gpio
    memory(gpio_port_address)=0xf;
    // write_memory(0xb0000000,0b11100|(1<<7));//uart csr
    memory(uart_csr_address)=(1<<uart_tx_enable)|(1<<uart_rx_enable)|(1<<uart_rx_interrupt_enable);
    // write_memory(0xb0000001,433);//uart buadrate 50M 115200
    memory(uart_buadrate_address)=433;// (1/buadrate)/(1/(f_clk))=(f_clk)/(baudrate)=50*10^6/115200
    interrupt_init();

    while(1)
    {
        
        if(a>=256)
        {
            a=0;
        }
        else
        {
            a++;
            
        }
        // write_memory(0xb0000001,0);
        // while(read_memort(0xb0000000)&(1<<5))
        // {}
        // while(read_memort(0xb0000000)&(1<<6))
        // {}
        test++;
        // if(send_enable)
        // {
        //     rx_data=memory(uart_rx_data_address);
        //     memory(uart_tx_data_address)=rx_data;
        //     send_enable=0;
        // }
        memory(gpio_port_address)=a;
        // delay(1000000);
        delay(500000);
        // write_memory(0xa0000001,0x5);
        // delay(1000000);


    }
    return 0;

}