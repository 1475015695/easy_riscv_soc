module core (
    input clk,
    input reset,


    input [3:0] bus_authority,
    output core_bus_req,
    input [31:0] core_read_address_in,
    input core_read_enable_in,
    input [31:0] core_read_data_in,
    output reg [31:0] core_read_address_out,
    output reg core_read_enable_out,
    output reg  [31:0] core_read_data_out,

    input [31:0] core_write_address_in,
    input [31:0] core_write_data_in,
    input core_write_enable_in,

    input start_program,
    input [31:0] flash_write_address_in,
    input [31:0] flash_write_data_in,
    input flash_write_enable_in,
    input program_done,

    output reg [31:0] core_write_address_out,
    output reg [31:0] core_write_data_out,
    output reg core_write_enable_out,

    output [31:0] mstatus_data,
    output [31:0] mie_data,
    input [31:0] interrupt_pend,
    input [31:0] interrupt_cause

    //output wire instruction_14
);

    
    
    //-----------------------csr_reg_inst---------------------
    
    localparam mvendorid_address=12'hf11,marchid_address=12'hf12,mimpid_address=12'hf13,mhartid_address=12'hf14,
    mstatus_address=12'h300,misa_address=12'h301,medeleg_address=12'h302,mideleg_address=12'h303,mie_address=12'h304,
    mtvec_address=12'h305,mcounteren_address=12'h306,
    mscratch_address=12'h340,mepc_address=12'h341,mcause_address=12'h342,mtval_address=12'h343,mip_address=12'h344;


    reg [11:0] csr_reg_write_address,csr_reg_read_address;
    reg [31:0] csr_reg_write_data;
    reg csr_reg_write_enable=1'b0;
    wire [31:0] csr_reg_read_data;
    wire [31:0] mstatus_data;//补丁，mret 指令需要同时读csr reg的mstatus，mepc两个数据，但我一开始只留了一个通道，所以直接把mstatus输出。


    wire interrupt_req;
    wire [31:0] interrupt_address;


    wire [11:0] csr_reg_address;
    assign csr_reg_address=instruction[31:20];
    wire [31:0] imm_csr_zext;
    assign imm_csr_zext={27'b0,instruction[19:15]};
    
    
    
    //-----------------------rom inst------------------------
    
    (* keep = "true" *) wire [31:0] instruction;
    
    
    //-----------------------alu inst------------------------
    localparam alu_op_add=5'd0,alu_op_slti=5'd1,alu_op_sltu=5'd2,
    alu_op_xori=5'd3,alu_op_ori=5'd4,alu_op_andi=5'd5,alu_op_slli=5'd6,alu_op_srli=5'd7,
    alu_op_srai=5'd8,alu_op_sub=5'd9,alu_op_sll=5'd10,alu_op_slt=5'd11,
    alu_op_xor=5'd13,alu_op_srl=5'd14,alu_op_sra=5'd15,alu_op_or=5'd16,alu_op_and=5'd17,
    alu_op_beq=5'd18,alu_op_bne=5'd19,alu_op_blt=5'd20,alu_op_bge=5'd21,alu_op_bltu=5'd22,
    alu_op_bgeu=5'd23;

    
    reg [4:0] alu_op;
    reg [31:0] alu_opa,alu_opb;
    wire [31:0] alu_result;
    wire alu_result_is_zero;
    
    
    //-----------------------reg inst------------------------
    reg [4:0] reg_write_address;
    reg [31:0] reg_write_data;
    reg reg_write_enable=1'b0;
    reg [4:0] reg_read_a_address;
    reg [4:0] reg_read_b_address;
    wire [31:0] reg_read_a_data;
    wire [31:0] reg_read_b_data;
    
    
    
    //------------------------------------------------
    //-------------------------------------------------
    //-------------------------------------------------------
    reg [31:0] pc_buff;
    reg [31:0] pc_inc;
    reg [31:0] pc_jump;
    (* mark_debug = "true" *)reg [31:0] pc_true;
    reg jump=1'b0;

    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [4:0] shamt;
    wire [31:0] imm_u;
    wire [20:0] imm_j;
    wire [11:0] imm_i;
    wire [12:0] imm_b;
    wire [11:0] imm_s;

    wire [31:0] imm_j_sext;
    wire [31:0] imm_i_sext;
    wire [31:0] imm_b_sext;
    wire [31:0] imm_s_sext;


    assign rs1=instruction[19:15];
    assign rs2=instruction[24:20];
    assign rd=instruction[11:7];
    assign shamt=instruction[24:20];

    assign imm_u={instruction[31:12],12'b0};
    assign imm_j={instruction[31],instruction[19:12],instruction[20],instruction[31:21],1'b0};//符号位扩展
    assign imm_i=instruction[31:20];
    assign imm_b={instruction[31],instruction[7],instruction[30:25],instruction[11:8],1'b0} ;
    assign imm_s={instruction[31:25],instruction[11:7]};

    assign imm_j_sext={{11{imm_j[20]}},imm_j};
    assign imm_i_sext={{20{imm_i[11]}},imm_i};
    assign imm_b_sext={{19{imm_b[12]}},imm_b};
    assign imm_s_sext={{20{imm_s[11]}},imm_s};
    //--------------------------------------program-------------------------------
    (* mark_debug = "true" *)reg programing=1'b0;
    always @(posedge clk ) begin
        if(reset)begin
            programing<=1'b0;
        end
        else if(start_program)begin
            programing<=1'b1;
        end
        else if(program_done)begin
            programing<=1'b0;
        end
    end
    //------------------------------------phase------------------------------------
    (* mark_debug = "true" *)reg [2:0] phase=3'b0;
    always @(posedge clk ) begin
        if(reset|programing)begin
            phase<=3'd7;//复位应然phase处于最后一个phase，下一个时钟上升沿phase才正确对应0
        end
        else if(core_hold_on)begin
            phase<=phase;
        end
        else if(phase==3'd7)begin
            phase<=3'b0;
        end
        else begin
            phase<=phase+1'b1;
        end
    end
    //------------------------------------pc----------------------------------------
    
    wire core_hold_on;
    wire mem_operation_hold_on;

    assign core_bus_req=core_read_enable_out|core_write_enable_out;
    assign mem_operation_hold_on=(core_bus_req&&(bus_authority!=4'd0));//core 接在m0上
    assign core_hold_on=mem_operation_hold_on;//以后可能有其他导致core hold的情况就加在这


    // assign pc_true=interrupt_req?interrupt_address:(jump?pc_jump:pc_inc);
    // assign pc_true=core_hold_on?pc_buff:(interrupt_req?:interrupt_address:(jump?pc_jump:pc_inc));
    always@(posedge clk)begin
        if(reset|programing)begin
            pc_true<=32'b0;
        end
        else if(phase==3'd5)begin//phase==5再执行,phase==6时就确定好了下一个pc
            if(core_hold_on)begin
                pc_true<=pc_buff;
            end
            else if(interrupt_req)begin
                pc_true<=interrupt_address;
            end
            else if(jump)begin
                pc_true<=pc_jump;
            end
            else begin
                pc_true<=pc_inc;
            end    
        end
        
    end

    always @(posedge clk ) begin
        if(reset)begin
            pc_inc<=32'b0;          
        end
        else begin
            pc_inc<=pc_true+3'd4;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            pc_buff<=32'b0;
        end
        else begin
            pc_buff<=pc_true; 
        end
    end


    always @(posedge clk ) begin
        if(reset)begin
            reg_read_a_address<=32'b0;
        end
        else if(phase==3'd7)begin
            case(instruction[6:0])
                7'b110_0111,
                7'b110_0011,
                7'b000_0011,
                7'b010_0011,
                7'b001_0011,
                7'b011_0011,
                7'b111_0011
                :begin
                    reg_read_a_address<=rs1;
                end
                default:begin
                    reg_read_a_address<=32'b0;
                end
            endcase
        end
        // else if(phase==3'd1)begin//跳转需要reg 数据
        //     case(instruction[6:0])
        //         7'b110_0011
        //         :begin
        //             reg_read_a_address<=rs1;
        //         end
        //     endcase 
        // end
        // else begin
        //     reg_read_a_address<=32'b0;
        // end
    end

    always @(posedge clk ) begin
        if(reset)begin
            reg_read_b_address<=32'b0;
        end
        else if(phase==3'd7)begin
            case(instruction[6:0])
                7'b110_0011,
                7'b010_0011,
                7'b011_0011
                :begin
                    reg_read_b_address<=rs2;
                end
                default:begin
                    reg_read_b_address<=32'b0;
                end
            endcase
        end
        // else if(phase==3'd1)begin//跳转需要reg 数据
        //     case(instruction[6:0])
        //         7'b110_0011
        //         :begin
        //             reg_read_b_address<=rs2;
        //         end
        //     endcase
        // end
        // else begin
        //     reg_read_b_address<=32'b0;
        // end
    end

    always @(posedge clk ) begin
        if(reset)begin
            alu_opa<=32'b0;
        end
        else if(phase==3'd1)begin
            case(instruction[6:0])
                7'b001_0111,
                7'b110_1111,
                7'b110_0011
                :begin
                    alu_opa<=pc_buff;
                end
                7'b110_0111,
                7'b000_0011,
                7'b010_0011,
                7'b001_0011,
                7'b011_0011
                :begin
                    alu_opa<=reg_read_a_data;
                end
                7'b111_0011
                    :begin
                        case(instruction[14:12])
                            3'b110,
                            3'b111
                                :begin
                                    alu_opa<=imm_csr_zext;
                                end
                        endcase
                    end
                default:begin
                    alu_opa<=32'b0;
                end
            endcase

        end
        else begin
            alu_opa<=32'b0;
        end
    end


    always @(posedge clk ) begin
        if(reset)begin
            alu_opb<=32'b0;
        end
        else if(phase==3'd1)begin
            case(instruction[6:0])
                7'b001_0111
                    :begin
                        alu_opb<=imm_u;
                    end
                7'b110_1111
                    :begin
                        alu_opb<=imm_j_sext;
                    end
                7'b110_0111,
                7'b000_0011
                    :begin
                        alu_opb<=imm_i_sext;
                    end
                7'b001_0011
                    :begin
                        case(instruction[14:12])
                            3'b000,
                            3'b010,
                            3'b011,
                            3'b100,
                            3'b110,
                            3'b111
                                :begin
                                    alu_opb<=imm_i_sext;
                                end
                            3'b001,
                            3'b101
                                :begin
                                    alu_opb<=shamt;
                                end
                        endcase
                    end
                7'b110_0011
                    :begin
                        alu_opb<=imm_b_sext;
                    end
                7'b010_0011
                    :begin
                        alu_opb<=imm_s_sext;
                    end
                7'b011_0011
                    :begin
                        case(instruction[14:12])
                            3'b000,
                            3'b010,
                            3'b011,
                            3'b100,
                            3'b110,
                            3'b111
                                :begin
                                    alu_opb<=reg_read_b_data;
                                end
                            3'b001,
                            3'b101
                                :begin
                                    alu_opb<={27'b0,reg_read_b_data[4:0]};
                                end
                        endcase
                    end
                7'b111_0011
                    :begin
                        alu_opb<=csr_reg_read_data;
                    end
                default:begin
                    alu_opb<=32'b0;
                end

            endcase

        end
        else begin
            alu_opb<=32'b0;
        end
    end

        always @(posedge clk ) begin
        if(reset)begin
            alu_op<=5'b0;
        end
        else if(phase==3'd1)begin
            case(instruction[6:0])
                7'b001_0111,
                7'b110_1111,
                7'b110_0111,
                7'b110_0011,
                7'b000_0011,
                7'b010_0011
                    :begin
                        alu_op<=alu_op_add;
                    end
                7'b001_0011
                    :begin
                        case(instruction[14:12])
                            3'b000
                                :begin
                                    alu_op<=alu_op_add;
                                end 
                            3'b010
                                :begin
                                    alu_op<=alu_op_slti;
                                end
                            3'b011
                                :begin
                                    alu_op<=alu_op_sltu;
                                end
                            3'b100
                                :begin
                                    alu_op<=alu_op_xori;
                                end
                            3'b110
                                :begin
                                    alu_op<=alu_op_ori;
                                end
                            3'b111
                                :begin
                                    alu_op<=alu_op_andi;
                                end
                            3'b001
                                :begin
                                    alu_op<=alu_op_slli;
                                end
                            3'b101
                                :begin
                                    case(instruction[30])
                                        1'b0
                                            :begin
                                                alu_op<=alu_op_srli;
                                            end
                                        1'b1
                                            :begin
                                                alu_op<=alu_op_srai;
                                            end
                                    endcase
                                end
                        endcase
                    end
                7'b011_0011
                    :begin
                        case(instruction[14:12])
                            3'b000
                                :begin
                                    case(instruction[30])
                                        1'b0
                                            :begin
                                                alu_op<=alu_op_add;
                                            end
                                        1'b1
                                            :begin
                                                alu_op<=alu_op_sub;
                                            end
                                    endcase
                                end
                            3'b001
                                :begin
                                    alu_op<=alu_op_sll;
                                end
                            3'b010
                                :begin
                                    alu_op<=alu_op_slt;
                                end
                            3'b011
                                :begin
                                    alu_op<=alu_op_sltu;
                                end
                            3'b100
                                :begin
                                    alu_op<=alu_op_xor;
                                end
                            3'b101
                                :begin
                                    case(instruction[30])
                                        1'b0
                                            :begin
                                                alu_op<=alu_op_srl;
                                            end
                                        1'b1
                                            :begin
                                                alu_op<=alu_op_sra;
                                            end
                                    endcase
                                end
                            3'b110
                                :begin
                                    alu_op<=alu_op_or;
                                end
                            3'b111
                                :begin
                                    alu_op<=alu_op_and;
                                end

                        endcase
                    end
                7'b111_0011
                    :begin
                        case(instruction[14:12])
                            3'b010
                                :begin
                                    alu_op<=alu_op_or;
                                end
                            3'b011
                                :begin
                                    alu_op<=alu_op_and;
                                end
                            3'b110
                                :begin
                                    alu_op<=alu_op_or;
                                end
                            3'b111
                                :begin
                                    alu_op<=alu_op_and;
                                end
                        endcase
                    end
                7'b111_0011
                    :begin
                        alu_op<=csr_reg_read_data;
                    end
                default:begin
                    alu_op<=5'b0;
                end

            endcase

        end
        else begin
            alu_op<=5'b0;
        end
    end

    always @(posedge clk ) begin//只关使能，保持地址，因为地址一变bus会切换接口，数据来不及传输
        if(reset)begin
            core_read_address_out<=32'b0;
            core_read_enable_out<=1'b0;
        end
        else if(phase==3'd3)begin
            case(instruction[6:0])
                7'b000_0011,
                7'b010_0011
                    :begin
                        core_read_address_out<=alu_result;
                        core_read_enable_out<=1'b1;
                    end
                default begin
                    core_read_address_out<=core_read_address_out;
                    core_read_enable_out<=1'b0;
                end
            endcase
        end
        else if(phase==3'd4&&bus_authority!=4'd0)begin
            core_read_address_out<=core_read_address_out;
            core_read_enable_out<=core_read_enable_out;
        end
        else begin//会占用总线，所以不保持信号
            core_read_address_out<=core_read_address_out;
            core_read_enable_out<=1'b0;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            reg_write_address<=32'b0;
            reg_write_enable<=1'b0;
        end
        else if(phase==3'd5)begin
            case(instruction[6:0])
                7'b011_0111,
                7'b001_0111,
                7'b110_1111,
                7'b110_0111,
                7'b000_0011,
                7'b001_0011,
                7'b011_0011,
                7'b111_0011
                    :begin
                        reg_write_address<=rd;
                        reg_write_enable<=1'b1;
                    end
                default begin
                    reg_write_address<=32'b0;
                    reg_write_enable<=1'b0;
                end
            endcase
        end
        else begin
            reg_write_address<=32'b0;
            reg_write_enable<=1'b0;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            reg_write_data<=32'b0;
        end
        else if(phase==3'd5)begin
            case(instruction[6:0])
                7'b011_0111
                    :begin
                        reg_write_data<=imm_u;
                    end
                7'b001_0111,
                7'b001_0011,
                7'b011_0011
                    :begin
                        reg_write_data<=alu_result;
                    end
                7'b110_1111,
                7'b110_0111
                    :begin
                        reg_write_data<=pc_buff+3'd4;
                    end
                7'b000_0011
                    :begin
                        case(instruction[14:12])
                            3'b000
                                :begin
                                    reg_write_data<={{24{core_read_data_in[7]}},core_read_data_in[7:0]};
                                end
                            3'b001
                                :begin
                                    reg_write_data<={{16{core_read_data_in[15]}},core_read_data_in[15:0]};
                                end
                            3'b010
                                :begin
                                    reg_write_data<=core_read_data_in;
                                end
                            3'b100
                                :begin
                                    reg_write_data<={24'b0,core_read_data_in[7:0]};
                                end
                            3'b101
                                :begin
                                    reg_write_data<={16'b0,core_read_data_in[15:0]};
                                end
                        endcase
                    end
                7'b111_0011
                    :begin
                        case(instruction[14:12])
                            3'b001,
                            3'b010,
                            3'b011,
                            3'b101,
                            3'b110,
                            3'b111
                                :begin
                                    reg_write_data<=csr_reg_read_data;
                                end
                        endcase
                    end
                default begin
                    reg_write_data<=32'b0;
                end
            endcase
        end
        // else begin
        //     reg_write_data<=32'b0;
        // end
    end

    always @(posedge clk ) begin//只关使能，保持地址，因为地址一变bus会切换接口，数据来不及传输
        if(reset)begin
            core_write_address_out<=32'b0;
            core_write_enable_out<=1'b0;
        end
        else if(phase==3'd5)begin
            case(instruction[6:0])
                7'b010_0011
                    :begin
                        core_write_address_out<=alu_result;
                        core_write_enable_out<=1'b1;
                    end
                default begin
                    core_write_address_out<=core_write_address_out;
                    core_write_enable_out<=1'b0;
                end
            endcase
        end
        else if(phase==3'd6&&bus_authority!=4'd0)begin
            core_write_enable_out<=core_write_enable_out;
            core_write_address_out<=core_write_address_out;
        end
        else begin
            core_write_address_out<=core_write_address_out;
            core_write_enable_out<=1'b0;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            core_write_data_out<=32'b0;
        end
        else if(phase==3'd5)begin
            case(instruction[6:0])
                7'b010_0011
                    :begin
                        case(instruction[14:12])
                            3'b000
                                :begin
                                    core_write_data_out<={core_read_data_in[31:8],reg_read_b_data[7:0]};
                                end
                            3'b001
                                :begin
                                    core_write_data_out<={core_read_data_in[31:16],reg_read_b_data[15:0]};
                                end
                            3'b010
                                :begin
                                    core_write_data_out<=reg_read_b_data;
                                end
                        endcase
                    end
                default begin
                    core_write_data_out<=32'b0;
                end
            endcase
        end
        // else if(phase==3'd4&&bus_authority!=4'd0)begin
        //     core_write_data_out<=core_write_data_out;
        // end
        // else begin
        //     core_write_data_out<=32'b0;
        // end
    end

    // always @(posedge clk ) begin
    //     if(reset)begin
    //         core_bus_req<=1'b0;
    //     end
    //     else if(phase==3'd4)begin
    //         case(instruction[6:0])
    //             7'b000_0011
    //                 :begin
    //                     core_bus_req<=1'b1;
    //                 end
    //             7'b010_0011
    //                 :begin
    //                     core_bus_req<=1'b1;
    //                 end
    //             default begin
    //                 core_bus_req<=1'b0;
    //             end
    //         endcase
    //     end
    //     else begin
    //         core_bus_req<=1'b0;
    //     end
    // end

    always @(posedge clk ) begin
        if(reset)begin
            pc_jump<=32'b0;
        end
        else if(phase==3'd4)begin
            case(instruction[6:0])
                7'b110_1111,
                7'b110_0011
                    :begin
                        pc_jump<=alu_result;
                    end
                7'b110_0111
                    :begin
                        pc_jump<={alu_result[31:1],1'b0};
                    end
                7'b111_0011
                    :begin
                        pc_jump<=csr_reg_read_data;
                    end
                default begin
                    pc_jump<=32'b0;
                end
            endcase
        end
        else begin
            pc_jump<=32'b0;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            jump<=1'b0;
        end
        else if(phase==3'd4)begin
            case(instruction[6:0])
                7'b110_1111,
                7'b110_0111
                    :begin
                        jump<=1'b1;
                    end
                7'b110_0011:begin
                    case(instruction[14:12])
                        3'b000:begin//beq if (rs1 == rs2)   pc += sext(offset)
                            if(reg_read_a_data==reg_read_b_data)begin
                                jump<=1'b1;
                            end
                        end
                        3'b001:begin//bne if (rs1 ≠ rs2) pc += sext(offset)
                            if($signed(reg_read_a_data)!=$signed(reg_read_b_data))begin
                                jump<=1'b1;
                            end
                        end
                        3'b100:begin//blt if (rs1 < rs2) pc += sext(offset)
                            if($signed(reg_read_a_data)<$signed(reg_read_b_data))begin
                                jump<=1'b1;
                            end
                        end
                        3'b101:begin//bge if (rs1 >= rs2) pc += sext(offset)
                            if(($signed(reg_read_a_data)>$signed(reg_read_b_data))||($signed(reg_read_a_data)==$signed(reg_read_b_data)))begin
                                jump<=1'b1;
                            end
                        end
                        3'b110:begin//bltu if (rs1 < rs2(unsigned)) pc += sext(offset)//TODO (unsigned)
                            if($unsigned(reg_read_a_data)<$unsigned(reg_read_b_data))begin
                                jump<=1'b1;
                            end
                        end
                        3'b111:begin//bgeu if (rs1 >= rs2) pc += sext(offset)//TODO (unsigned)
                            if(($unsigned(reg_read_a_data)>$unsigned(reg_read_b_data))||($unsigned(reg_read_a_data)==$unsigned(reg_read_b_data)))begin
                                jump<=1'b1;
                            end
                        end
                    endcase
                end
                7'b111_0011:begin
                    case(instruction[14:12])
                        3'b000:begin
                            case(instruction[31:25])
                                7'b0011_000:begin//mret
                                    jump<=1'b1;
                                end
                                default begin
                                    jump<=1'b0;
                                end
                            endcase    
                        end
                    endcase
                end
                default begin
                    jump<=1'b0;
                end
            endcase
        end
        else begin
            jump<=1'b0;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            csr_reg_read_address<=32'b0;
        end
        else if(phase==3'd7)begin//mret 要提前读到地址
            case(instruction[6:0])
                7'b111_0011
                    :begin
                        case(instruction[14:12])
                            3'b000
                                :begin
                                    case(instruction[31:25])
                                        7'b0011_000
                                            :begin
                                                csr_reg_read_address<=mepc_address;
                                            end
                                    endcase
                                end
                            3'b001,
                            3'b010,
                            3'b011,
                            3'b101,
                            3'b110,
                            3'b111
                                :begin
                                    csr_reg_read_address<=csr_reg_address;
                                end
                        endcase
                    end
            endcase
        end
        // else begin
        //     csr_reg_read_address<=32'b0;
        // end
    end

    always @(posedge clk ) begin
        if(reset)begin
            csr_reg_write_address<=32'b0;
            csr_reg_write_enable<=1'b0;
        end
        else if(phase==3'd4)begin
            case(instruction[6:0])
                7'b111_0011
                    :begin
                        case(instruction[14:12])
                            3'b000
                                :begin
                                    case(instruction[31:25])
                                        7'b0011_000
                                            :begin
                                                csr_reg_write_address<=mstatus_address;
                                                csr_reg_write_enable<=1'b1;
                                            end
                                    endcase
                                end
                            3'b001,
                            3'b010,
                            3'b011,
                            3'b101,
                            3'b110,
                            3'b111
                                :begin
                                    csr_reg_write_address<=csr_reg_address;
                                    csr_reg_write_enable<=1'b1;
                                end
                        endcase

                    end
                
            endcase
        end
        else begin
            csr_reg_write_address<=32'b0;
            csr_reg_write_enable<=1'b0;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            csr_reg_write_data<=32'b0;
        end
        else if(phase==3'd4)begin
            case(instruction[6:0])
                7'b111_0011
                    :begin
                        case(instruction[14:12])
                            3'b000
                                :begin
                                    case(instruction[31:25])
                                        7'b0011_000
                                            :begin
                                                csr_reg_write_data<={mstatus_data[31:8],mstatus_data[7:4],mstatus_data[7:4]};
                                            end
                                    endcase
                                end
                            3'b001
                                :begin
                                    csr_reg_write_data<=reg_read_a_data;
                                end
                            3'b010,
                            3'b011,
                            3'b110,
                            3'b111
                                :begin
                                    csr_reg_write_data<=alu_result;
                                end                
                            3'b101
                                :begin
                                    csr_reg_write_data<=imm_csr_zext;
                                end
                        endcase

                    end
                
            endcase
        end
        // else begin
        //     csr_reg_write_data<=32'b0;
        // end
    end



    
    register register_inst0(
        .clk(clk),
        .reg_write_address(reg_write_address),
        .reg_write_data(reg_write_data),
        .reg_write_enable(reg_write_enable),
        .reg_read_a_address(reg_read_a_address),
        .reg_read_b_address(reg_read_b_address),
        .reg_read_a_data(reg_read_a_data),
        .reg_read_b_data(reg_read_b_data)
    );
    csr_reg csr_reg_inst0(
        .clk(clk),
        .csr_reg_write_address(csr_reg_write_address),
        .csr_reg_write_data(csr_reg_write_data),
        .csr_reg_write_enable(csr_reg_write_enable),
        .csr_reg_read_address(csr_reg_read_address),
        .csr_reg_read_data(csr_reg_read_data),

        .mstatus_data(mstatus_data),
        .mie_data(mie_data),

        .core_hold_on(core_hold_on),
        .phase(phase),
        .pc_buff(pc_buff),
        .jump(jump),
        .pc_jump(pc_jump),
        .interrupt_req(interrupt_req),
        .interrupt_address(interrupt_address),


        .interrupt_pend(interrupt_pend),
        .interrupt_cause(interrupt_cause)



    );
    // rom rom_inst0(                       //sim
    //     .clka(clk),
    //     .addra(pc_true[14:0]),
    //     .douta(instruction)
    // );
    // rom rom_inst0(                       //vivado
    //     .clka(clk),
    //     .addra({17'b0,2'b0,pc_true[14:2]}),
    //     .douta(instruction)
    // );
    flash flash_inst0(
        .clka(clk),
        .clkb(clk),
        .addrb({2'b0,pc_true[14:2]}),
        //.mem_read_enable(mem_read_enable),
        .doutb(instruction),
        .addra(flash_write_address_in[14:0]),
        .dina(flash_write_data_in),
        .wea(flash_write_enable_in)
    );

    // blk_mem_gen_0 rom_inst0(                       //vivado
    //     .clka(clk),
    //     .addra({2'b0,pc_true[14:2]}),
    //     .douta(instruction)
    // );

    alu alu_inst0(
        .clk(clk),
        .phase(phase),
        .op(alu_op),
        .opa(alu_opa),
        .opb(alu_opb),
        .alu_result(alu_result),
        .alu_result_is_zero(alu_result_is_zero)
    );

endmodule //core