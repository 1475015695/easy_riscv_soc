module gpio (
    input clk,
    input reset,
    input [31:0] gpio_read_address,
    output reg [31:0] gpio_read_data,
    input [31:0] gpio_write_address,
    input [31:0] gpio_write_data,
    input gpio_write_enable,


    output [9:0] gpio_port
);
    reg [31:0] gpio_csr_reg=32'b0;
    reg [31:0] gpio_port_reg=32'b0;
    localparam gpio_csr_address=32'ha000_0000,gpio_port_address=32'ha000_0001;
    assign gpio_port=gpio_port_reg[9:0];
    always @(posedge clk ) begin
        if(reset)begin
            gpio_csr_reg<=32'b0;
            gpio_port_reg<=32'b0;
        end
        else if(gpio_write_enable)begin
            case(gpio_write_address)
                gpio_csr_address:begin
                    gpio_csr_reg<=gpio_write_data;
                end
                gpio_port_address:begin
                    gpio_port_reg<=gpio_write_data;
                end
            endcase
        end
    end

    always @(posedge clk ) begin
        case(gpio_read_address)
            gpio_csr_address:begin
                gpio_read_data<=gpio_csr_reg;
            end
            gpio_port_address:begin
                gpio_read_data<={22'b0,gpio_port};
            end
        endcase
    end


endmodule //gpio