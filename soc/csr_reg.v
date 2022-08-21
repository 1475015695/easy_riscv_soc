module csr_reg (
    input clk,
    input reset,
    input [11:0] csr_reg_write_address,
    input [31:0] csr_reg_write_data,
    input csr_reg_write_enable,
    input [11:0] csr_reg_read_address,
    output reg [31:0] csr_reg_read_data,
    output [31:0] mstatus_data,
    output [31:0] mie_data,


    input core_hold_on,//core hold on 时保持中断请求
    input [2:0] phase,//phase!=3同时又有中断请求时保持中断请求，
    input [31:0] pc_buff,
    input jump,
    input [31:0] pc_jump,
    output wire [31:0] interrupt_address,
    input [31:0] interrupt_pend,
    input [31:0] interrupt_cause,
    output reg interrupt_req
);
    localparam mvendorid_address=12'hf11,marchid_address=12'hf12,mimpid_address=12'hf13,mhartid_address=12'hf14,
    mstatus_address=12'h300,misa_address=12'h301,medeleg_address=12'h302,mideleg_address=12'h303,mie_address=12'h304,
    mtvec_address=12'h305,mcounteren_address=12'h306,
    mscratch_address=12'h340,mepc_address=12'h341,mcause_address=12'h342,mtval_address=12'h343,mip_address=12'h344;
    //reg [31:0] csr_reg [7:0];//只实现了trap相关的寄存器。

    (* keep = "true" *) reg [31:0] mtvec=32'b0;
    (* keep = "true" *) reg [31:0] mepc=32'b0;
    (* keep = "true" *) reg [31:0] mcause=32'b0;
    (* keep = "true" *) reg [31:0] mtval=32'b0;
    (* keep = "true" *) reg [31:0] mstatus=32'b0;
    (* keep = "true" *) reg [31:0] mscratch=32'b0;
    (* keep = "true" *) reg [31:0] mie=32'b0;
    (* keep = "true" *) reg [31:0] mip=32'b0;

    assign mstatus_data=mstatus;
    assign mie_data=mie;
    assign interrupt_address={2'b0,mtvec[31:2]};
    // assign mepc=mcause[31]?pc_buff+3'd4:pcbuff;
    always @(posedge clk ) begin
        if(csr_reg_write_enable)begin
            case(csr_reg_write_address)
                mtvec_address:begin
                    mtvec<=csr_reg_write_data;
                end
                mtval_address:begin
                    mtval<=csr_reg_write_data;
                end
                mstatus_address:begin
                    mstatus<=csr_reg_write_data;
                end
                mscratch_address:begin
                    mscratch<=csr_reg_write_data;
                end
                mie_address:begin
                    mie<=csr_reg_write_data;
                end
                default:begin
                    
                end

            endcase
        end
        else if(interrupt_req)begin
            mstatus<={mstatus[31:4],4'b0};
        end
    end

    always@(posedge clk)begin
        if(reset)begin
            csr_reg_read_data<=32'b0;
        end
        else begin
            case(csr_reg_read_address)
                mtvec_address:begin
                    csr_reg_read_data<=mtvec;
                end
                mepc_address:begin
                    csr_reg_read_data<=mepc;
                end
                mcause_address:begin
                    csr_reg_read_data<=mcause;
                end
                mtval_address:begin
                    csr_reg_read_data<=mtval;
                end
                mstatus_address:begin
                    csr_reg_read_data<=mstatus;
                end
                mscratch_address:begin
                    csr_reg_read_data<=mscratch;
                end
                mie_address:begin
                    csr_reg_read_data<=mie;
                end
                mip_address:begin
                    csr_reg_read_data<=mip;
                end
                default:begin
                    csr_reg_read_data<=32'b0;
                end
            endcase
        end
        
    end

    //----------------------------------trap-------------------------------------------
    always @(posedge clk ) begin
        if(reset)begin
            interrupt_req<=1'b0;
        end
        else if(mstatus[3] && mie[7] && (interrupt_pend))begin

            // mcause <= mcause|32'h8000_0080;//中断、定时器中断
            mcause <= {1'b1,interrupt_pend[30:0]};//设7为定时器中断，16为rx中断
            interrupt_req<=1'b1;
        end//timer_int
        else if(core_hold_on||(phase!=3'd5&&interrupt_req))begin
            interrupt_req<=interrupt_req;
        end
        else begin
            interrupt_req<=1'b0;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            mepc<=32'b0;
        end
        else if(interrupt_req)begin
            if(jump)begin
                mepc<=pc_jump;
            end
            else begin
                mepc<=pc_buff+3'd4;
            end
        end
    end

    always @(posedge clk ) begin
        mip<=interrupt_pend;
    end

    

endmodule //csr_reg