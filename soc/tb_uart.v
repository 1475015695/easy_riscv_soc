`timescale 1ns/1ps
module tb_uart (
    
);

    localparam tx_buadrate_9600_count=16'd5207,tx_buadrate_19200_count=16'd2603,tx_buadrate_38400_count=16'd1301,tx_buadrate_57600_count=16'd867,tx_buadrate_115200_count=16'd433;//50M
    localparam uart_csr_reg_address=32'hb000_0000,uart_buadrate_address=32'hb000_0001,uart_tx_data_address=32'hb000_0002,uart_rx_data_address=32'hb000_0003;
    reg clk=1'b0;
    reg reset=1'b1;
    wire test_uart_to_soc;
    reg [31:0] test_uart_write_address,test_uart_write_data,test_uart_read_address;
    wire [31:0] test_uart_read_data;
    reg test_uart_write_enable;
    uart uart_inst0 (
    .clk(clk),
    .reset(reset),
    .uart_write_address(test_uart_write_address),
    .uart_write_data(test_uart_write_data),
    .uart_write_enable(test_uart_write_enable),
    .uart_read_address(test_uart_read_address),
    .uart_read_data(test_uart_read_data),
    .uart_tx(test_uart_to_soc)
    );

    soc soc_inst0(
        .clk(clk),
        .reset(reset),
        .uart_rx(test_uart_to_soc)
    );

    always #10 clk=!clk;

    initial begin
        $dumpfile("wave");
        $dumpvars();

        $readmemh("initrom.txt",soc_inst0.core_inst0.flash_inst0.flash);
        // $readmemh("initrom.txt",instruction_top_inst0.rom_inst0.rom);
        //$readmemh("D:/Project/vivado/li_riscv3/compile/initrom.txt",soc_inst0.core_inst0.rom_inst0.inst.native_mem_module.blk_mem_gen_v8_4_1_inst.memory);
        reset=1'b1;
        #20;
        reset=1'b0;
        #20;
        test_uart_write_address=uart_csr_reg_address;//csr
        test_uart_write_data=32'b1_0011;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;

        #20;
        test_uart_write_address=uart_buadrate_address;//buadrate
        test_uart_write_data=tx_buadrate_115200_count;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;

        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0001;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;

        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0002;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0003;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0004;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
//----------------------------------------------------end start_frame
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0010;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)

        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0020;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)

        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0030;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)

        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0040;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
//instruction1
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0050;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0060;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0070;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0080;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
//--------------------------------------------------------end transform

//---------------------------------------------------------end frame
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_00f0;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_000f;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_00a5;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_005a;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        
        #5000;
        wait(soc_inst0.uart_inst0.rx_save_frame==0)

        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0070;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0080;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
//-----------------------------------------------------------anther frame
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_005a;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_00a5;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_000f;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_00f0;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        //----------------------------------------------------end start_frame
        //instruction2
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0050;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0060;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0070;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_0080;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
//--------------------------------------------------------end transform
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_00f0;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_000f;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_00a5;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #20;
        test_uart_write_address=uart_tx_data_address;
        test_uart_write_data=32'h0000_005a;
        test_uart_write_enable=1'b1;
        #20;
        test_uart_write_enable=1'b0;
        wait(uart_inst0.tx_send_frame==0)
        #400;
        wait(soc_inst0.uart_inst0.rx_save_frame==0)
        #50000;
        $finish;
    end


endmodule //tb_program