.section .text
.globl _start

_start:
    li ra,0
    li gp,0
    li tp,0
    li s0,0
    la sp,stack_start

    


    la t0,data_start_bin#254 初始化的数据才需要加载 bin就是ld文件里的flash块
    la t1,data_start_mem#3c00 mem就是ram
    la t2,data_end_mem#3c08
    blt t1,t2,carry_data 
1:

    la t0,bss_start_mem#3c08 没有bss在flash段的起始地址因为bss段是未初始化的变量，只需要清零该变量在mem中的地址
    la t1,bss_end_mem
    blt t0,t1,clear_bss
2:   
    call main

carry_data:
    lw t3,(t0)
    sw t3,(t1)
    addi t1,t1,4
    addi t0,t0,4
    blt t1,t2,carry_data
    j 1b

clear_bss:
    sw zero,(t0)
    addi t0,t0,4
    blt t0, t1,clear_bss
    j 2b 

loop:
    j loop
