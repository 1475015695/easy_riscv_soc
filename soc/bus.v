module bus (
    input clk,
    input reset,

    output reg [3:0] bus_authority,

    input m0_bus_req,
    input [31:0] m0_read_address_out,//m0读别人地址
    output reg [31:0] m0_read_address_in,//m0被别人读的地址
    input m0_read_enable_out,//m0读别人使能
    output reg m0_read_enable_in,
    input [31:0] m0_read_data_out,//m0被读的数据
    output reg [31:0] m0_read_data_in,//m0读到的别人的数据
    input [31:0] m0_write_address_out,//m0写别人地址
    output reg [31:0] m0_write_address_in,//m0被别人写地址
    output reg [31:0] m0_write_data_in,//m0被写的数据
    input [31:0] m0_write_data_out,//m0写别人的数据
    input m0_write_enable_out,//m0写别人使能
    output reg m0_write_enable_in,//m0被被写使能

    input m1_bus_req,
    input [31:0] m1_read_address_out,//m1读别人地址
    output reg [31:0] m1_read_address_in,//m1被别人读的地址
    input m1_read_enable_out,//m0读别人使能
    output reg m1_read_enable_in,
    input [31:0] m1_read_data_out,//m1被读的数据
    output reg [31:0] m1_read_data_in,//m1读到的别人的数据
    input [31:0] m1_write_address_out,//m1写别人地址
    output reg [31:0] m1_write_address_in,//m1被别人写地址
    output reg [31:0] m1_write_data_in,//m1被写的数据
    input [31:0] m1_write_data_out,//m1写别人的数据
    input m1_write_enable_out,//m1写别人使能
    output reg m1_write_enable_in,//m1被被写使能

    

    input m2_bus_req,
    input [31:0] m2_read_address_out,//m2读别人地址
    output reg [31:0] m2_read_address_in,//m2被别人读的地址
    input m2_read_enable_out,//m2读别人使能
    output reg m2_read_enable_in,
    input [31:0] m2_read_data_out,//m2被读的数据
    output reg [31:0] m2_read_data_in,//m2读到的别人的数据
    input [31:0] m2_write_address_out,//m2写别人地址
    output reg [31:0] m2_write_address_in,//m2被别人写地址
    output reg [31:0] m2_write_data_in,//m2被写的数据
    input [31:0] m2_write_data_out,//m2写别人的数据
    input m2_write_enable_out,//m2写别人使能
    output reg m2_write_enable_in,//m2被被写使能

    input m3_bus_req,
    input [31:0] m3_read_address_out,//m3读别人地址
    output reg [31:0] m3_read_address_in,//m3被别人读的地址
    input m3_read_enable_out,//m3读别人使能
    output reg m3_read_enable_in,
    input [31:0] m3_read_data_out,//m3被读的数据
    output reg [31:0] m3_read_data_in,//m3读到的别人的数据
    input [31:0] m3_write_address_out,//m3写别人地址
    output reg [31:0] m3_write_address_in,//m3被别人写地址
    output reg [31:0] m3_write_data_in,//m3被写的数据
    input [31:0] m3_write_data_out,//m3写别人的数据
    input m3_write_enable_out,//m3写别人使能
    output reg m3_write_enable_in,//m3被被写使能

    output reg [31:0] s0_read_address_in,
    output reg s0_read_enable_in,
    input [31:0] s0_read_data_out,
    output reg [31:0] s0_write_address_in,
    output reg [31:0] s0_write_data_in,
    output reg s0_write_enable_in,

    output reg [31:0] s1_read_address_in,
    output reg s1_read_enable_in,
    input [31:0] s1_read_data_out,
    output reg [31:0] s1_write_address_in,
    output reg [31:0] s1_write_data_in,
    output reg s1_write_enable_in,

    output reg [31:0] s2_read_address_in,
    output reg s2_read_enable_in,
    input [31:0] s2_read_data_out,
    output reg [31:0] s2_write_address_in,
    output reg [31:0] s2_write_data_in,
    output reg s2_write_enable_in,

    output reg [31:0] s3_read_address_in,
    output reg s3_read_enable_in,
    input [31:0] s3_read_data_out,
    output reg [31:0] s3_write_address_in,
    output reg [31:0] s3_write_data_in,
    output reg s3_write_enable_in

);

    localparam m0_bus_address=4'b0000,m1_bus_address=4'b0001,m2_bus_address=4'd2,m3_bus_address=4'd3;
    localparam s0_bus_address=4'd8,s1_bus_address=4'd9,s2_bus_address=4'd10,s3_bus_address=4'd11;
    localparam authority_to_m0=4'd0,authority_to_m1=4'd1,authority_to_m2=4'd2,authority_to_m3=4'd3;

    always @(posedge clk ) begin
        if(m0_bus_req||reset)begin
            bus_authority<=authority_to_m0;
        end
        else if(m1_bus_req)begin
            bus_authority<=authority_to_m1;
        end
        else if(m2_bus_req)begin
            bus_authority<=authority_to_m2;
        end
        else if(m3_bus_req)begin
            bus_authority<=authority_to_m3;
        end
        else begin
            bus_authority<=authority_to_m0;
        end

    end

    always @(*) begin
        // s0_write_enable_in=1'b0;//读写地址一变，接口切换可能快于信号切换，可能写使能就一直被拉高了
        // s1_write_enable_in=1'b0;
        // s2_write_enable_in=1'b0;
        // s0_read_enable_in=1'b0;//读写地址一变，接口切换可能快于信号切换，可能写使能就一直被拉高了
        // s1_read_enable_in=1'b0;
        // s2_read_enable_in=1'b0;
        case(bus_authority)
            authority_to_m0:begin
                case(m0_read_address_out[31:28])
                    m0_bus_address:begin
                        m0_read_address_in=m0_read_address_out;
                        m0_read_enable_in=m0_read_enable_out;
                        m0_read_data_in=m0_read_data_out;
                    end
                    m1_bus_address:begin
                        m1_read_address_in=m0_read_address_out;
                        m1_read_enable_in=m0_read_enable_out;
                        m0_read_data_in=m1_read_data_out;
                    end
                    m2_bus_address:begin
                        m2_read_address_in=m0_read_address_out;
                        m2_read_enable_in=m0_read_enable_out;
                        m0_read_data_in=m2_read_data_out;
                    end
                    m3_bus_address:begin
                        m3_read_address_in=m0_read_address_out;
                        m3_read_enable_in=m0_read_enable_out;
                        m0_read_data_in=m3_read_data_out;
                    end
                    s0_bus_address:begin
                        s0_read_address_in=m0_read_address_out;
                        s0_read_enable_in=m0_read_enable_out;
                        m0_read_data_in=s0_read_data_out;
                    end
                    s1_bus_address:begin
                        s1_read_address_in=m0_read_address_out;
                        s1_read_enable_in=m0_read_enable_out;
                        m0_read_data_in=s1_read_data_out;
                    end
                    s2_bus_address:begin
                        s2_read_address_in=m0_read_address_out;
                        s2_read_enable_in=m0_read_enable_out;
                        m0_read_data_in=s2_read_data_out;
                    end
                    s3_bus_address:begin
                        s3_read_address_in=m0_read_address_out;
                        s3_read_enable_in=m0_read_enable_out;
                        m0_read_data_in=s3_read_data_out;
                    end
                endcase
                case(m0_write_address_out[31:28])
                    m0_bus_address:begin
                        m0_write_address_in=m0_write_address_out;
                        m0_write_data_in=m0_write_data_out;
                        m0_write_enable_in=m0_write_enable_out;
                    end
                    m1_bus_address:begin
                        m1_write_address_in=m0_write_address_out;
                        m1_write_data_in=m0_write_data_out;
                        m1_write_enable_in=m0_write_enable_out;
                    end
                    m2_bus_address:begin
                        m2_write_address_in=m0_write_address_out;
                        m2_write_data_in=m0_write_data_out;
                        m2_write_enable_in=m0_write_enable_out;
                    end
                    m3_bus_address:begin
                        m3_write_address_in=m0_write_address_out;
                        m3_write_data_in=m0_write_data_out;
                        m3_write_enable_in=m0_write_enable_out;
                    end
                    s0_bus_address:begin
                        s0_write_address_in=m0_write_address_out;
                        s0_write_data_in=m0_write_data_out;
                        s0_write_enable_in=m0_write_enable_out;
                        
                        s1_write_enable_in=1'b0;
                        s2_write_enable_in=1'b0;
                        s3_write_enable_in=1'b0;
                    end
                    s1_bus_address:begin
                        s1_write_address_in=m0_write_address_out;
                        s1_write_data_in=m0_write_data_out;
                        s1_write_enable_in=m0_write_enable_out;

                        s0_write_enable_in=1'b0;//读写地址一变，接口切换可能快于信号切换，可能写使能就一直被拉高了
                        s2_write_enable_in=1'b0;
                        s3_write_enable_in=1'b0;
                    end
                    s2_bus_address:begin
                        s2_write_address_in=m0_write_address_out;
                        s2_write_data_in=m0_write_data_out;
                        s2_write_enable_in=m0_write_enable_out;

                        s0_write_enable_in=1'b0;//读写地址一变，接口切换可能快于信号切换，可能写使能就一直被拉高了
                        s1_write_enable_in=1'b0;
                        s3_write_enable_in=1'b0;
                    end
                    s3_bus_address:begin
                        s3_write_address_in=m0_write_address_out;
                        s3_write_data_in=m0_write_data_out;
                        s3_write_enable_in=m0_write_enable_out;

                        s0_write_enable_in=1'b0;//读写地址一变，接口切换可能快于信号切换，可能写使能就一直被拉高了
                        s1_write_enable_in=1'b0;
                        s2_write_enable_in=1'b0;
                    end
                endcase
            end

            authority_to_m1:begin
            
                case(m1_read_address_out[31:28])
                    m0_bus_address:begin
                        m0_read_address_in=m1_read_address_out;
                        m0_read_enable_in=m1_read_enable_out;
                        m1_read_data_in=m0_read_data_out;
                    end
                    m1_bus_address:begin
                        m1_read_address_in=m1_read_address_out;
                        m1_read_enable_in=m1_read_enable_out;
                        m1_read_data_in=m1_read_data_out;
                    end
                    m2_bus_address:begin
                        m2_read_address_in=m1_read_address_out;
                        m2_read_enable_in=m1_read_enable_out;
                        m1_read_data_in=m2_read_data_out;
                    end
                    m3_bus_address:begin
                        m3_read_address_in=m1_read_address_out;
                        m3_read_enable_in=m1_read_enable_out;
                        m1_read_data_in=m3_read_data_out;
                    end
                    s0_bus_address:begin
                        s0_read_address_in=m1_read_address_out;
                        s0_read_enable_in=m1_read_enable_out;
                        m1_read_data_in=s0_read_data_out;
                    end
                    s1_bus_address:begin
                        s1_read_address_in=m1_read_address_out;
                        s1_read_enable_in=m1_read_enable_out;
                        m1_read_data_in=s1_read_data_out;
                    end
                    s2_bus_address:begin
                        s2_read_address_in=m1_read_address_out;
                        s2_read_enable_in=m1_read_enable_out;
                        m1_read_data_in=s2_read_data_out;
                    end
                endcase
                case(m1_write_address_out[31:28])
                    m0_bus_address:begin
                        m0_write_address_in=m1_write_address_out;
                        m0_write_data_in=m1_write_data_out;
                        m0_write_enable_in=m1_write_enable_out;
                    end
                    m1_bus_address:begin
                        m1_write_address_in=m1_write_address_out;
                        m1_write_data_in=m1_write_data_out;
                        m1_write_enable_in=m1_write_enable_out;
                    end
                    m2_bus_address:begin
                        m2_write_address_in=m1_write_address_out;
                        m2_write_data_in=m1_write_data_out;
                        m2_write_enable_in=m1_write_enable_out;
                    end
                    m3_bus_address:begin
                        m3_write_address_in=m1_write_address_out;
                        m3_write_data_in=m1_write_data_out;
                        m3_write_enable_in=m1_write_enable_out;
                    end
                    s0_bus_address:begin
                        s0_write_address_in=m1_write_address_out;
                        s0_write_data_in=m1_write_data_out;
                        s0_write_enable_in=m1_write_enable_out;
                    end
                    s1_bus_address:begin
                        s1_write_address_in=m1_write_address_out;
                        s1_write_data_in=m1_write_data_out;
                        s1_write_enable_in=m1_write_enable_out;
                    end
                    s2_bus_address:begin
                        s2_write_address_in=m1_write_address_out;
                        s2_write_data_in=m1_write_data_out;
                        s2_write_enable_in=m1_write_enable_out;
                    end
                endcase
            end
            authority_to_m2:begin
            
                case(m2_read_address_out[31:28])
                    m0_bus_address:begin
                        m0_read_address_in=m2_read_address_out;
                        m0_read_enable_in=m2_read_enable_out;
                        m2_read_data_in=m0_read_data_out;
                    end
                    m1_bus_address:begin
                        m1_read_address_in=m2_read_address_out;
                        m1_read_enable_in=m2_read_enable_out;
                        m2_read_data_in=m1_read_data_out;
                    end
                    m2_bus_address:begin
                        m2_read_address_in=m2_read_address_out;
                        m2_read_enable_in=m2_read_enable_out;
                        m2_read_data_in=m2_read_data_out;
                    end
                    m3_bus_address:begin
                        m3_read_address_in=m2_read_address_out;
                        m3_read_enable_in=m2_read_enable_out;
                        m2_read_data_in=m3_read_data_out;
                    end
                    s0_bus_address:begin
                        s0_read_address_in=m2_read_address_out;
                        s0_read_enable_in=m2_read_enable_out;
                        m2_read_data_in=s0_read_data_out;
                    end
                    s1_bus_address:begin
                        s1_read_address_in=m2_read_address_out;
                        s1_read_enable_in=m2_read_enable_out;
                        m2_read_data_in=s1_read_data_out;
                    end
                    s2_bus_address:begin
                        s2_read_address_in=m2_read_address_out;
                        s2_read_enable_in=m2_read_enable_out;
                        m2_read_data_in=s2_read_data_out;
                    end
                endcase
                case(m2_write_address_out[31:28])
                    m0_bus_address:begin
                        m0_write_address_in=m2_write_address_out;
                        m0_write_data_in=m2_write_data_out;
                        m0_write_enable_in=m2_write_enable_out;
                    end
                    m1_bus_address:begin
                        m1_write_address_in=m2_write_address_out;
                        m1_write_data_in=m2_write_data_out;
                        m1_write_enable_in=m2_write_enable_out;
                    end
                    m2_bus_address:begin
                        m2_write_address_in=m2_write_address_out;
                        m2_write_data_in=m2_write_data_out;
                        m2_write_enable_in=m2_write_enable_out;
                    end
                    m3_bus_address:begin
                        m3_write_address_in=m2_write_address_out;
                        m3_write_data_in=m2_write_data_out;
                        m3_write_enable_in=m2_write_enable_out;
                    end
                    s0_bus_address:begin
                        s0_write_address_in=m2_write_address_out;
                        s0_write_data_in=m2_write_data_out;
                        s0_write_enable_in=m2_write_enable_out;
                    end
                    s1_bus_address:begin
                        s1_write_address_in=m2_write_address_out;
                        s1_write_data_in=m2_write_data_out;
                        s1_write_enable_in=m2_write_enable_out;
                    end
                    s2_bus_address:begin
                        s2_write_address_in=m2_write_address_out;
                        s2_write_data_in=m2_write_data_out;
                        s2_write_enable_in=m2_write_enable_out;
                    end
                endcase
            end
            authority_to_m3:begin
            
                case(m3_read_address_out[31:28])
                    m0_bus_address:begin
                        m0_read_address_in=m3_read_address_out;
                        m0_read_enable_in=m3_read_enable_out;
                        m3_read_data_in=m0_read_data_out;
                    end
                    m1_bus_address:begin
                        m1_read_address_in=m3_read_address_out;
                        m1_read_enable_in=m3_read_enable_out;
                        m3_read_data_in=m1_read_data_out;
                    end
                    m2_bus_address:begin
                        m2_read_address_in=m3_read_address_out;
                        m2_read_enable_in=m3_read_enable_out;
                        m3_read_data_in=m2_read_data_out;
                    end
                    m3_bus_address:begin
                        m3_read_address_in=m3_read_address_out;
                        m3_read_enable_in=m3_read_enable_out;
                        m3_read_data_in=m3_read_data_out;
                    end
                    s0_bus_address:begin
                        s0_read_address_in=m3_read_address_out;
                        s0_read_enable_in=m3_read_enable_out;
                        m3_read_data_in=s0_read_data_out;
                    end
                    s1_bus_address:begin
                        s1_read_address_in=m3_read_address_out;
                        s1_read_enable_in=m3_read_enable_out;
                        m3_read_data_in=s1_read_data_out;
                    end
                    s2_bus_address:begin
                        s2_read_address_in=m3_read_address_out;
                        s2_read_enable_in=m3_read_enable_out;
                        m3_read_data_in=s2_read_data_out;
                    end

                endcase
                case(m3_write_address_out[31:28])
                    m0_bus_address:begin
                        m0_write_address_in=m3_write_address_out;
                        m0_write_data_in=m3_write_data_out;
                        m0_write_enable_in=m3_write_enable_out;
                    end
                    m1_bus_address:begin
                        m1_write_address_in=m3_write_address_out;
                        m1_write_data_in=m3_write_data_out;
                        m1_write_enable_in=m3_write_enable_out;
                    end
                    m2_bus_address:begin
                        m2_write_address_in=m3_write_address_out;
                        m2_write_data_in=m3_write_data_out;
                        m2_write_enable_in=m3_write_enable_out;
                    end
                    m3_bus_address:begin
                        m3_write_address_in=m3_write_address_out;
                        m3_write_data_in=m3_write_data_out;
                        m3_write_enable_in=m3_write_enable_out;
                    end
                    s0_bus_address:begin
                        s0_write_address_in=m3_write_address_out;
                        s0_write_data_in=m3_write_data_out;
                        s0_write_enable_in=m3_write_enable_out;
                    end
                    s1_bus_address:begin
                        s1_write_address_in=m3_write_address_out;
                        s1_write_data_in=m3_write_data_out;
                        s1_write_enable_in=m3_write_enable_out;
                    end
                    s2_bus_address:begin
                        s2_write_address_in=m3_write_address_out;
                        s2_write_data_in=m3_write_data_out;
                        s2_write_enable_in=m3_write_enable_out;
                    end
                endcase
            end
        endcase
    end

endmodule //bus