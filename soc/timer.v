module timer (
    input clk,
    input reset,
    input [3:0] bus_authority,

    input [31:0] timer_read_address_in,
    output reg [31:0] timer_read_data_out,

    input [31:0] timer_write_address_in,
    input [31:0] timer_write_data_in,
    input timer_write_enable_in,


    input [31:0] mstatus_data,
    input [31:0] mie_data,
    output reg timer_int_req
);
    localparam timer_csr_address=32'h9000_0000,timer_count_address=32'h9000_0001;
    reg [31:0] timer_csr;//控制b0:enable
    reg [31:0] timer_count;//计数
    reg [31:0] timer_counter;
    // assign timer_int_req=(timer_counter==timer_count)&(timer_csr[0]);
    
    always @(posedge clk ) begin
        if(reset)begin
            timer_csr<=32'b0;
            timer_count<=32'b0;
        end
        else if(timer_write_enable_in)begin
            if(timer_write_address_in==timer_csr_address)begin
                timer_csr<=timer_write_data_in;
            end
            else if(timer_write_address_in==timer_count_address)begin
                timer_count<=timer_write_data_in;
            end
        end
    end
    always@(*)begin
        if(timer_read_address_in==timer_csr_address)begin
            timer_read_data_out=timer_csr;
        end
        else if(timer_read_address_in==timer_count_address)begin
            timer_read_data_out=timer_count;
        end
    end
    
    always @(posedge clk ) begin
        if(reset)begin
            timer_counter<=32'b0;
            timer_int_req<=1'b0;
        end
        else if(timer_csr[0]&&mstatus_data[3]&&mie_data[7])begin
            if(timer_counter==timer_count)begin
                timer_counter<=32'b0;
                timer_int_req<=1'b1;
            end
            else begin
                timer_counter<=timer_counter+1'b1;
                timer_int_req<=1'b0;
            end
            
        end
        else begin
            timer_counter<=32'b0;
            timer_int_req<=1'b0;
        end
    end

endmodule //timer