module register (
    input clk,
    input reset,
    input [4:0] reg_write_address,
    input [31:0] reg_write_data,
    input reg_write_enable,

    input  [4:0] reg_read_a_address,
    input  [4:0] reg_read_b_address,
    output reg [31:0] reg_read_a_data,
    output reg [31:0] reg_read_b_data  
);
    (* keep = "true" *) reg [31:0] register [31:0];

    (* keep = "true" *) wire [4:0] reg_write_address_w;
    assign reg_write_address_w=reg_write_address;
    (* keep = "true" *) wire [31:0] reg_write_data_w;
    assign reg_write_data_w=reg_write_data;
    (* keep = "true" *) wire reg_write_enable_w;
    assign reg_write_enable_w=reg_write_enable;
    (* keep = "true" *) wire [4:0] reg_read_a_address_w;
    assign reg_read_a_address_w=reg_read_a_address;
    (* keep = "true" *) wire [4:0] reg_read_b_address_w;
    assign reg_read_b_address_w=reg_read_b_address;
    (* keep = "true" *) wire [31:0] reg_read_a_data_w;
    assign reg_read_a_data_w=reg_read_a_data;
    (* keep = "true" *) wire [31:0] reg_read_b_data_w;
    assign reg_read_b_data_w=reg_read_b_data;



    always @(posedge clk ) begin
        if(reset)begin

        end
        else if(reg_write_enable)begin
            if(reg_write_address==5'b0)begin
                
            end
            else begin
                register[reg_write_address]<=reg_write_data; 
            end
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            reg_read_a_data<=32'b0;
            reg_read_b_data<=32'b0;
        end
        else begin
            reg_read_a_data<=(reg_read_a_address==5'b0)?32'b0:register[reg_read_a_address];
            reg_read_b_data<=(reg_read_b_address==5'b0)?32'b0:register[reg_read_b_address];
        end
    end
    

endmodule //register