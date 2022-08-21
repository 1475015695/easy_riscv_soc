module board (
    input sys_clk,
    input reset,
    output [9:0] gpio_port,
    output uart_tx,
    input uart_rx
);
    wire clk;
    clk_wiz_0 clk_inst0(
        .reset(reset),
        .clk_in1(sys_clk),
        .clk_out1(clk)


    );
    soc soc_inst0(
        .clk(clk),
        .reset(reset),
        .gpio_port(gpio_port),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );
endmodule //board