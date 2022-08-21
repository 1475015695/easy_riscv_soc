`timescale 1ns/1ps

module tb_soc_vivado (
    
);

    reg clk=1'b0;
    reg reset=1'b0;
    soc soc_inst0(
        .clk(clk),
        .reset(reset)
    );

    always #10 clk=!clk;

    initial begin
        $dumpfile("wave");
        $dumpvars();

        // $readmemh("initrom.txt",soc_inst0.core_inst0.rom_inst0.rom);
        // $readmemh("initrom.txt",instruction_top_inst0.rom_inst0.rom);
        //$readmemh("D:/Project/vivado/li_riscv3/compile/initrom.txt",soc_inst0.core_inst0.rom_inst0.inst.native_mem_module.blk_mem_gen_v8_4_1_inst.memory);
        reset=1'b1;
        #20;
        reset=1'b0;
        // #20;
        // reset=1'b1;
        #5000000;
        $finish;

    end


endmodule //tb_soc