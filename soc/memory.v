module memory (
    input clka,
    input clkb,
    input [14:0] addrb,
    output reg [31:0] doutb,

    input [14:0] addra,//32k
    input [31:0] dina,
    input wea
    
    
);
    reg [31:0] memory [32767:0];//2^15 (* ram_style = "block" *) 
    //assign mem_read_data=memory[mem_read_address[31:2]];//{memory[mem_read_address+2'd3],memory[mem_read_address+2'd2],memory[mem_read_address+2'd1],memory[mem_read_address]};

    always @(posedge clka ) begin
        if(wea)begin
            memory[addra]<=dina;
            // memory[mem_write_address+2'd3]<=mem_write_data[31:24];
            // memory[mem_write_address+2'd2]<=mem_write_data[23:16];
            // memory[mem_write_address+2'd1]<=mem_write_data[15:8];
            // memory[mem_write_address]<=mem_write_data[7:0];
        end
    end

    always @(posedge clkb ) begin
        if(addra==addrb&&wea)begin//写优先
            doutb<=dina;
        end
        else begin
           doutb<=memory[addrb]; 
        end
    end

endmodule //memory