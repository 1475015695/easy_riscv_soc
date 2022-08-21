#include "interrupt.h"
#include "common.h"

void write_timer_csr(uint csr_address,uint csr_data)
{
    write_memory(csr_address,csr_data);
    
}