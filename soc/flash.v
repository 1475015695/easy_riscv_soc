module flash (
    input clka,
    input clkb,
    input [14:0] addrb,
    output reg [31:0] doutb,

    input [14:0] addra,//32k
    input [31:0] dina,
    input wea
);
    reg [31:0] flash [32767:0];
    always @(posedge clka ) begin
        if(wea)begin
            flash[addra]<=dina;
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
           doutb<=flash[addrb]; 
        end
    end

endmodule //rom