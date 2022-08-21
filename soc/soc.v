module soc (
    input clk,
    input reset,//7z020默认低电平，按下高电平
    output [9:0] gpio_port,
    output uart_tx,
    input uart_rx
);
    // wire reset=!reset_n; 
    //------------------------------------test bus var--------------------
    wire test_bus_req;

    //----------------------------------------bus var--------------------------
    wire [3:0] bus_authority;
    //------------------------core var-------------------------------
    wire core_bus_req;
    wire [31:0] core_read_address_in,core_read_address_out,core_read_data_in,core_read_data_out,
    core_write_address_in,core_write_data_in,core_write_address_out,core_write_data_out;
    wire core_write_enable_in,core_write_enable_out,core_read_enable_out,core_read_enable_in;
    //----------------------------uart var------------------------------------
    wire start_program,program_done;
    wire [31:0] flash_write_address,flash_write_data;
    wire flash_write_enable;
    wire [31:0] uart_write_address,uart_write_data,uart_read_address,uart_read_data;
    wire uart_write_enable;
    wire uart_rx_int_req;

    
    wire [31:0] mstatus_data,mie_data;
    //-------------------------memory var---------------------------
    (* keep = "true" *) wire [31:0] mem_read_address,mem_read_data,mem_write_address,mem_write_data;
    (* keep = "true" *) wire mem_write_enable,mem_read_enable;
    //-----------------------timer var-----------------------------
    wire timer_int_req;
    wire timer_bus_req,timer_write_enable_in;
    wire [31:0] timer_read_address_in,timer_read_data_out,timer_write_address_in,timer_write_data_in;
    //----------------------------------------gpio var------------------
    wire [31:0] gpio_read_address,gpio_read_data,gpio_write_address,gpio_write_data;
    wire gpio_write_enable;

    //----------------------------------------bus inst--------------------------
    bus bus_inst0(
        .clk(clk),
        .reset(reset),
        .bus_authority(bus_authority),

        .m0_bus_req(core_bus_req),
        .m0_read_address_out(core_read_address_out),
        .m0_read_address_in(core_read_address_in),
        .m0_read_data_out(core_read_data_out),
        .m0_read_data_in(core_read_data_in),
        .m0_read_enable_out(core_read_enable_out),
        .m0_read_enable_in(core_read_enable_in),
        .m0_write_address_out(core_write_address_out),
        .m0_write_address_in(core_write_address_in),
        .m0_write_data_in(core_write_data_in),
        .m0_write_data_out(core_write_data_out),
        .m0_write_enable_out(core_write_enable_out),
        .m0_write_enable_in(core_write_enable_in),

        .s0_read_address_in(mem_read_address),
        .s0_read_enable_in(mem_read_enable),
        .s0_read_data_out(mem_read_data),
        .s0_write_address_in(mem_write_address),
        .s0_write_data_in(mem_write_data),
        .s0_write_enable_in(mem_write_enable),

        .s1_read_address_in(timer_read_address_in),
        .s1_read_data_out(timer_read_data_out),
        .s1_write_address_in(timer_write_address_in),
        .s1_write_data_in(timer_write_data_in),
        .s1_write_enable_in(timer_write_enable_in),

        .s2_read_address_in(gpio_read_address),
        .s2_read_data_out(gpio_read_data),
        .s2_write_address_in(gpio_write_address),
        .s2_write_data_in(gpio_write_data),
        .s2_write_enable_in(gpio_write_enable),

        .s3_read_address_in(uart_read_address),
        .s3_read_data_out(uart_read_data),
        .s3_write_address_in(uart_write_address),
        .s3_write_data_in(uart_write_data),
        .s3_write_enable_in(uart_write_enable)

    );
    //------------------------core_inst0-------------------------------
    
    core core_inst0(
        .clk(clk),
        .reset(reset),

        .bus_authority(bus_authority),
        .core_bus_req(core_bus_req),
        .core_read_address_in(core_read_address_in),
        .core_read_address_out(core_read_address_out),
        .core_read_data_in(core_read_data_in),
        .core_read_data_out(core_read_data_out),
        .core_read_enable_out(core_read_enable_out),
        .core_read_enable_in(core_read_enable_in),
        .core_write_address_in(core_write_address_in),
        .core_write_data_in(core_write_data_in),
        .core_write_enable_in(core_write_enable_in),
        .core_write_address_out(core_write_address_out),
        .core_write_data_out(core_write_data_out),
        .core_write_enable_out(core_write_enable_out),


        .start_program(start_program),
        .flash_write_address_in(flash_write_address),
        .flash_write_data_in(flash_write_data),
        .flash_write_enable_in(flash_write_enable),
        .program_done(program_done),

        .mstatus_data(mstatus_data),
        .mie_data(mie_data),
        .interrupt_pend({15'b0,uart_rx_int_req,8'b0,timer_int_req,7'b0}),//>=16为平台使用的中断号
        .interrupt_cause(32'b0)

        

    );

    //-------------------------memory inst---------------------------
    memory memory_inst0(
        .clka(clk),
        .clkb(clk),
        .addrb({2'b0,mem_read_address[14:2]}),
        //.mem_read_enable(mem_read_enable),
        .doutb(mem_read_data),
        .addra({2'b0,mem_write_address[14:2]}),
        .dina(mem_write_data),
        .wea(mem_write_enable)
    );
    //-----------------------timer inst-----------------------------
    
    timer timer_inst0(
        .clk(clk),
        .reset(reset),
        .bus_authority(bus_authority),
        .timer_read_address_in(timer_read_address_in),
        .timer_read_data_out(timer_read_data_out),
        .timer_write_address_in(timer_write_address_in),
        .timer_write_data_in(timer_write_data_in),
        .timer_write_enable_in(timer_write_enable_in),


        .mstatus_data(mstatus_data),
        .mie_data(mie_data),
        .timer_int_req(timer_int_req)
    );
    //----------------------------------------gpio inst------------------
    
    gpio gpio_inst0(
        .clk(clk),
        .reset(reset),
        .gpio_read_address(gpio_read_address),
        .gpio_read_data(gpio_read_data),
        .gpio_write_address(gpio_write_address),
        .gpio_write_data(gpio_write_data),
        .gpio_write_enable(gpio_write_enable),
        .gpio_port(gpio_port[9:0])
    );
    // //------------------------------------test bus inst--------------------
    
    // bus_test bus_test_inst0(
    //     .clk(clk),
    //     .bus_authority(bus_authority),
    //     .test_bus_req(test_bus_req)
    // );

    //-----------------------------------uart inst ----------------------------
    
    uart uart_inst0 (
    .clk(clk),
    .reset(reset),
    .uart_write_address(uart_write_address),
    .uart_write_data(uart_write_data),
    .uart_write_enable(uart_write_enable),
    .uart_read_address(uart_read_address),
    .uart_read_data(uart_read_data),
    // .uart_tx_done,//keep 1 clock when tx done
    // .uart_state,//0 idle 1 busy
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .uart_rx_int_req(uart_rx_int_req),

    .start_program(start_program),
    .flash_write_address(flash_write_address),
    .flash_write_data(flash_write_data),
    .flash_write_enable(flash_write_enable),
    .program_done(program_done)
);

endmodule //soc