//由于vivado ram读需要一个时钟，为了统一起见将单周期改为了双周期

module core (
    input clk,
    input reset,


    input [3:0] bus_authority,
    output reg core_bus_req,
    input [31:0] core_read_address_in,
    input core_read_enable_in,
    input [31:0] core_read_data_in,
    output reg [31:0] core_read_address_out,
    output reg core_read_enable_out,
    output reg  [31:0] core_read_data_out,

    input [31:0] core_write_address_in,
    input [31:0] core_write_data_in,
    input core_write_enable_in,

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
    alu_op_xor=5'd13,alu_op_srl=5'd14,alu_op_sra=5'd15,alu_op_or=5'd16,alu_op_and=5'd17;

    
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
    reg [31:0] pc_true;
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
    //------------------------------------phase------------------------------------
    reg [1:0] phase=2'b0;
    always @(posedge clk ) begin
        if(reset)begin
            phase<=2'd3;//复位应然phase处于最后一个phase，下一个时钟上升沿phase才正确对应0
        end
        else if(core_hold_on)begin
            phase<=phase;
        end
        else if(phase==2'd3)begin
            phase<=2'b0;
        end
        else begin
            phase<=phase+1'b1;
        end
    end
    //------------------------------------pc----------------------------------------
    wire core_hold_on;
    wire mem_operation_hold_on;
    assign mem_operation_hold_on=(core_bus_req&&(bus_authority!=4'd0));//core 接在m0上
    assign core_hold_on=mem_operation_hold_on;//以后可能有其他导致core hold的情况就加在这
    // assign pc_true=interrupt_req?interrupt_address:(jump?pc_jump:pc_inc);
    // assign pc_true=core_hold_on?pc_buff:(interrupt_req?:interrupt_address:(jump?pc_jump:pc_inc));
    always@(posedge clk)begin
        if(phase==2'd2)begin//phase==2再执行,phase==3时就确定好了下一个pc
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
        pc_buff<=pc_true;
    end

    


    //-------------------------------------------------------------------------------
    always @(posedge clk ) begin
        reg_write_enable<=1'b0;
        core_write_enable_out<=1'b0;
        jump<=1'b0;
        csr_reg_write_enable<=1'b0;
        core_bus_req<=1'b0;
        core_read_enable_out<=1'b0;
        case (instruction[6:0])
            7'b011_0111:begin//lui 高位立即数加载 (Load Upper Immediate).//x[rd] = sext(immediate[31:12] << 12)

                reg_write_address<=rd;
                reg_write_data<=imm_u;
                reg_write_enable<=1'b1;
            end 
            7'b001_0111:begin//auipc   //把立即数左移12位加到当前pc  //x[rd] = pc + sext(immediate[31:12] << 12)
                alu_opa<=pc_buff;//当前pc
                alu_opb<=imm_u;//立即数
                alu_op<=alu_op_add;//auipc 对应op

                reg_write_address<=rd;
                reg_write_data<=alu_result;
                reg_write_enable<=1'b1;
            end
            7'b110_1111:begin//jal 跳转并链接 (Jump and  Link).//x[rd] <= pc+4; pc += sext(offset)

                alu_opa<=pc_buff;
                alu_opb<=imm_j_sext;//符号位扩展
                alu_op<=alu_op_add;
                pc_jump<=alu_result;
                jump<=1'b1;

                reg_write_address<=rd;
                reg_write_data<=pc_buff+3'd4;//这里pc_buff在每次clk上升沿再改变，也就是保持此时的pc值一个时钟周期，需要保持因为pc值可能会改变，但有指令又需要用到当前pc值。
                reg_write_enable<=1'b1;

            end
            7'b110_0111:begin//jalr //t <= pc + 4;  pc = (x[rs1]+sext(offset)) & 0xffff_fffe;  x[rd]=t

                reg_read_a_address<=rs1;
                alu_opa<=reg_read_a_data;
                alu_opb<=imm_i_sext;
                alu_op<=alu_op_add;
                pc_jump<={alu_result[31:1],1'b0};
                jump<=1'b1;

                reg_write_address<=rd;
                reg_write_data<=pc_buff+3'd4;
                reg_write_enable<=1'b1;

            end
            7'b110_0011:begin
                reg_read_a_address<=rs1;
                reg_read_b_address<=rs2;
                case(instruction[14:12])
                    3'b000:begin//beq if (rs1 == rs2)   pc += sext(offset)
                        if(reg_read_a_data==reg_read_b_data)begin
                            alu_opa<=pc_buff;
                            alu_opb<=imm_b_sext;
                            alu_op<=alu_op_add;
                            pc_jump<=alu_result;
                            jump<=1'b1;
                        end
                    end
                    3'b001:begin//bne if (rs1 ≠ rs2) pc += sext(offset)
                        if($signed(reg_read_a_data)!=$signed(reg_read_b_data))begin
                            alu_opa<=pc_buff;
                            alu_opb<=imm_b_sext;
                            alu_op<=alu_op_add;
                            pc_jump<=alu_result;
                            jump<=1'b1;
                        end
                    end
                    3'b100:begin//blt if (rs1 < rs2) pc += sext(offset)
                        if($signed(reg_read_a_data)<$signed(reg_read_b_data))begin
                            alu_opa<=pc_buff;
                            alu_opb<=imm_b_sext;
                            alu_op<=alu_op_add;
                            pc_jump<=alu_result;
                            jump<=1'b1;
                        end
                    end
                    3'b101:begin//bge if (rs1 >= rs2) pc += sext(offset)
                        if(($signed(reg_read_a_data)>$signed(reg_read_b_data))||($signed(reg_read_a_data)==$signed(reg_read_b_data)))begin
                            alu_opa<=pc_buff;
                            alu_opb<=imm_b_sext;
                            alu_op<=alu_op_add;
                            pc_jump<=alu_result;
                            jump<=1'b1;
                        end
                    end
                    3'b110:begin//bltu if (rs1 < rs2(unsigned)) pc += sext(offset)//TODO (unsigned)
                        if($unsigned(reg_read_a_data)<$unsigned(reg_read_b_data))begin
                            alu_opa<=pc_buff;
                            alu_opb<=imm_b_sext;
                            alu_op<=alu_op_add;
                            pc_jump<=alu_result;
                            jump<=1'b1;
                        end
                    end
                    3'b111:begin//bgeu if (rs1 >= rs2) pc += sext(offset)//TODO (unsigned)
                        if(($unsigned(reg_read_a_data)>$unsigned(reg_read_b_data))||($unsigned(reg_read_a_data)==$unsigned(reg_read_b_data)))begin
                            alu_opa<=pc_buff;
                            alu_opb<=imm_b_sext;
                            alu_op<=alu_op_add;
                            pc_jump<=alu_result;
                            jump<=1'b1;
                        end
                    end
                endcase
            end
            7'b000_0011:begin
                case(instruction[14:12])
                    3'b000:begin//lb x[rd] = sext(M[x[rs1] + sext(offset)][7:0]) 作用是从rs1加上offset的地址处读取一个字节的内容，并将该内容经符号位扩展后写入rd寄存器。
                        reg_read_a_address<=rs1;
                        alu_opa<=reg_read_a_data;//x[rs1]
                        alu_opb<=imm_i_sext;//sext(offset)
                        alu_op<=alu_op_add;
                        
                        core_bus_req<=1'b1;
                        core_read_address_out<=alu_result;
                        
                        
                        reg_write_data<={{24{core_read_data_in[7]}},core_read_data_in[7:0]};
                        reg_write_address<=rd;

                        if(phase==2'd2)begin//前一个时钟读数据
                            core_read_enable_out<=1'b1;
                        end
                        if(phase==2'd3)begin//后一个时钟写入
                            reg_write_enable<=1'b1;    
                        end
                        


                    end
                    3'b001:begin//lh //x[rd] = sext(M[x[rs1] + sext(offset)][15:0]) 作用是从rs1加上offset的地址处读取两个字节的内容，并将该内容经符号位扩展后写入rd寄存器。
                        reg_read_a_address<=rs1;
                        alu_opa<=reg_read_a_data;//x[rs1]
                        alu_opb<=imm_i_sext;//sext(offset)
                        alu_op<=alu_op_add;
                        
                        core_bus_req<=1'b1;
                        core_read_address_out<=alu_result;
                        
                        reg_write_data<={{16{core_read_data_in[15]}},core_read_data_in[15:0]};
                        reg_write_address<=rd;
                        if(phase==2'd2)begin//前一个时钟读数据
                            core_read_enable_out<=1'b1;
                        end
                        if(phase==2'd3)begin//后一个时钟写入
                            reg_write_enable<=1'b1;    
                        end
                    end
                    3'b010:begin//lw //x[rd] = sext(M[x[rs1] + sext(offset)][31:0]) 作用是从rs1加上offset的地址处读取四个字节的内容，结果写入rd寄存器。
                        reg_read_a_address<=rs1;
                        alu_opa<=reg_read_a_data;//x[rs1]
                        alu_opb<=imm_i_sext;//sext(offset)
                        alu_op<=alu_op_add;
                        
                        core_bus_req<=1'b1;
                        core_read_address_out<=alu_result;
                        
                        reg_write_data<=core_read_data_in;
                        reg_write_address<=rd;
                        if(phase==2'd2)begin//前一个时钟读数据
                            core_read_enable_out<=1'b1;
                        end
                        if(phase==2'd3)begin//后一个时钟写入
                            reg_write_enable<=1'b1;    
                        end
                    end
                    3'b100:begin//lbu //x[rd] = M[x[rs1] + sext(offset)][7:0] 作用是从rs1加上offset的地址处读取一个字节的内容，并将该内容经0扩展后写入rd寄存器。
                        reg_read_a_address<=rs1;
                        alu_opa<=reg_read_a_data;//x[rs1]
                        alu_opb<=imm_i_sext;//sext(offset)
                        alu_op<=alu_op_add;
                        
                        core_bus_req<=1'b1;
                        core_read_address_out<=alu_result;
                        
                        reg_write_data<={24'b0,core_read_data_in[7:0]};
                        reg_write_address<=rd;
                        if(phase==2'd2)begin//前一个时钟读数据
                            core_read_enable_out<=1'b1;
                        end
                        if(phase==2'd3)begin//后一个时钟写入
                            reg_write_enable<=1'b1;    
                        end
                    end
                    3'b101:begin//lhu //x[rd] = M[x[rs1] + sext(offset)][15:0] 作用是从rs1加上offset的地址处读取两个字节的内容，并将该内容经0扩展后写入rd寄存器。
                        reg_read_a_address<=rs1;
                        alu_opa<=reg_read_a_data;//x[rs1]
                        alu_opb<=imm_i_sext;//sext(offset)
                        alu_op<=alu_op_add;
                        
                        core_bus_req<=1'b1;
                        core_read_address_out<=alu_result;
                        
                        reg_write_data<={16'b0,core_read_data_in[15:0]};
                        reg_write_address<=rd;
                        if(phase==2'd2)begin//前一个时钟读数据
                            core_read_enable_out<=1'b1;
                        end
                        if(phase==2'd3)begin//后一个时钟写入
                            reg_write_enable<=1'b1;    
                        end
                    end
                    
                endcase
            end
            7'b010_0011:begin
                case(instruction[14:12])
                    3'b000:begin//sb //M[x[rs1] + sext(offset)] = x[rs2][7: 0]
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_s_sext;
                        alu_op<=alu_op_add;

                        core_bus_req<=1'b1;
                        core_read_address_out<=alu_result;             
                        core_write_address_out<=alu_result;
                        core_write_data_out<={core_read_data_in[31:8],reg_read_b_data[7:0]};
                        if(phase==2'd2)begin//前一个时钟读数据
                            core_read_enable_out<=1'b1;
                        end
                        if(phase==2'd3)begin//后一个时钟写入
                            core_write_enable_out<=1'b1;    
                        end

                        
                    end
                    3'b001:begin//sh  //M[x[rs1] + sext(offset) = x[rs2][15: 0]
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_s_sext;
                        alu_op<=alu_op_add;

                        core_bus_req<=1'b1;
                        core_write_address_out<=alu_result;
                        core_read_address_out<=alu_result;                       
                        core_write_data_out<={core_read_data_in[31:16],reg_read_b_data[15:0]};
                        if(phase==2'd2)begin//前一个时钟读数据
                            core_read_enable_out<=1'b1;
                        end
                        if(phase==2'd3)begin//后一个时钟写入
                            core_write_enable_out<=1'b1;    
                        end
                    end
                    3'b010:begin//sw //M[ x[rs1] + sext(offset) ] = x[rs2][31: 0]
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_s_sext;
                        alu_op<=alu_op_add;

                        core_bus_req<=1'b1;
                        core_write_address_out<=alu_result;
                        core_write_data_out<=reg_read_b_data;
                        if(phase==2'd3)begin//后一个时钟写入
                            core_write_enable_out<=1'b1;    
                        end
                    end
                endcase
            end
            7'b001_0011:begin
                case(instruction[14:12])
                    3'b000:begin//addi //x[rd] = x[rs1] + sext(immediate)
                        reg_read_a_address<=rs1;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_i_sext;
                        alu_op<=alu_op_add;

                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                    end
                    3'b010:begin//slti 小于则置位(Set if Less Than)  //x[rd] = (x[rs1] <s sext(immediate))
                        reg_read_a_address<=rs1;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_i_sext;
                        alu_op<=alu_op_slti;
                        
                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;


                        
                    end
                    3'b011:begin//sltiu 无符号小于立即数则置位(Set if Less Than Immediate, Unsigned).//x[rd] = (x[rs1] <u sext(immediate))
                        reg_read_a_address<=rs1;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_i_sext;
                        alu_op<=alu_op_sltu;
                        
                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                        
                    end
                    3'b100:begin//xori 立即数异或(Exclusive-OR Immediate).//x[rd] = x[rs1] ^ sext(immediate)
                        reg_read_a_address<=rs1;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_i_sext;
                        alu_op<=alu_op_xori;
                        
                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                        
                    end
                    3'b110:begin//ori
                        reg_read_a_address<=rs1;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_i_sext;
                        alu_op<=alu_op_ori;
                        
                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                    end
                    3'b111:begin//andi
                        reg_read_a_address<=rs1;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=imm_i_sext;
                        alu_op<=alu_op_andi;
                        
                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                    end
                    //---------------------------------------------------
                    3'b001:begin//slli 立即数逻辑左移(Shift Left Logical Immediate).//x[rd] = x[rs1] ≪ shamt
                        reg_read_a_address<=rs1;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=shamt;
                        alu_op<=alu_op_slli;

                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                        
                    end
                    3'b101:begin
                        case(instruction[30])
                            1'b0:begin//srli 立即数逻辑右移(Shift Right Logical Immediate).//x[rd] = (x[rs1] ≫u shamt)
                                reg_read_a_address<=rs1;

                                alu_opa<=reg_read_a_data;
                                alu_opb<=shamt;
                                alu_op<=alu_op_srli;

                                reg_write_address<=rd;
                                reg_write_data<=alu_result;
                                reg_write_enable<=1'b1;
                                

                            end
                            1'b1:begin//srai 立即数算术右移(Shift Right Arithmetic Immediate) //x[rd] = (x[rs1] ≫s shamt)
                                reg_read_a_address<=rs1;

                                alu_opa<=reg_read_a_data;
                                alu_opb<=shamt;
                                alu_op<=alu_op_srai;

                                reg_write_address<=rd;
                                reg_write_data<=alu_result;
                                reg_write_enable<=1'b1;
                                
                            end
                        endcase
                    end
                endcase
            end
            7'b011_0011:begin
                case(instruction[14:12])
                    3'b000:begin
                        case(instruction[30])
                            1'b0:begin//add 把寄存器 x[rs2]加到寄存器 x[rs1]上，结果写入 x[rd]。忽略算术溢出。//x[rd] = x[rs1] + x[rs2]
                                reg_read_a_address<=rs1;
                                reg_read_b_address<=rs2;

                                alu_opa<=reg_read_a_data;
                                alu_opb<=reg_read_b_data;
                                alu_op<=alu_op_add;

                                reg_write_address<=rd;
                                reg_write_data<=alu_result;
                                reg_write_enable<=1'b1;                
                                
                            end
                            1'b1:begin//sub 
                                reg_read_a_address<=rs1;
                                reg_read_b_address<=rs2;

                                alu_opa<=reg_read_a_data;
                                alu_opb<=reg_read_b_data;
                                alu_op<=alu_op_sub;

                                reg_write_address<=rd;
                                reg_write_data<=alu_result;
                                reg_write_enable<=1'b1; 
                            end
                        endcase
                    end
                    3'b001:begin//sll 逻辑左移(Shift Left Logical).//x[rd] = x[rs1] ≪ x[rs2] 把寄存器 x[rs1]左移 x[rs2]位，空出的位置填入 0，结果写入 x[rd]。 x[rs2]的低 5 位（如果是RV64I 则是低 6 位）代表移动位数，其高位则被忽略。
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=reg_read_b_data[4:0];
                        alu_op<=alu_op_sll;

                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1; 
                        
                    end
                    3'b010:begin//slt 小于则置位(Set if Less Than).//x[rd] = (x[rs1] <s x[rs2])
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=reg_read_b_data;
                        alu_op<=alu_op_slt;

                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                        
                    end
                    3'b011:begin//sltu 无符号小于则置位(Set if Less Than, Unsigned). //x[rd] = (x[rs1] <u x[rs2])
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=reg_read_b_data;
                        alu_op<=alu_op_sltu;

                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                        
                    end
                    3'b100:begin//xor 异或(Exclusive-OR).//x[rd] = x[rs1] ^ x[rs2]
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=reg_read_b_data;
                        alu_op<=alu_op_xor;

                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                        
                    end
                    3'b101:begin
                        case(instruction[30])
                            1'b0:begin//slr 逻辑右移(Shift Right Logical).//x[rd] = (x[rs1] ≫u x[rs2]) 把寄存器 x[rs1]右移 x[rs2]位，空出的位置填入 0，结果写入 x[rd]。 x[rs2]的低 5 位（如果是 RV64I 则是低 6 位）代表移动位数，其高位则被忽略。
                                reg_read_a_address<=rs1;
                                reg_read_b_address<=rs2;

                                alu_opa<=reg_read_a_data;
                                alu_opb<=reg_read_b_data[4:0];
                                alu_op<=alu_op_srl;

                                reg_write_address<=rd;
                                reg_write_data<=alu_result;
                                reg_write_enable<=1'b1;
                                
                            end
                            1'b1:begin//sra 算术右移(Shift Right Arithmetic). //x[rd] = (x[rs1] ≫s x[rs2]) 把寄存器 x[rs1]右移 x[rs2]位，空位用 x[rs1]的最高位填充，结果写入 x[rd]。 x[rs2]的低 5 位 （如果是 RV64I 则是低 6 位）为移动位数，高位则被忽略。
                                reg_read_a_address<=rs1;
                                reg_read_b_address<=rs2;

                                alu_opa<=reg_read_a_data;
                                alu_opb<=reg_read_b_data[4:0];
                                alu_op<=alu_op_sra;

                                reg_write_address<=rd;
                                reg_write_data<=alu_result;
                                reg_write_enable<=1'b1;
                                
                            end
                        endcase
                    end
                    3'b110:begin//or 
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=reg_read_b_data;
                        alu_op<=alu_op_or;

                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                    end
                    3'b111:begin//and
                        reg_read_a_address<=rs1;
                        reg_read_b_address<=rs2;

                        alu_opa<=reg_read_a_data;
                        alu_opb<=reg_read_b_data;
                        alu_op<=alu_op_and;

                        reg_write_address<=rd;
                        reg_write_data<=alu_result;
                        reg_write_enable<=1'b1;
                    end
                endcase
            end
            7'b000_1111:begin
                case(instruction[14:12])
                    3'b000:begin//fence 同步内存和 I/O(Fence Memory and I/O).//Fence(pred, succ)
                        
                        
                    end
                    3'b001:begin//fencei 
                        
                    end
                endcase
            end
            7'b111_0011:begin
                case(instruction[14:12])
                    3'b000:begin
                        case(instruction[31:25])
                            7'b0011_000:begin//mret
                                csr_reg_read_address<=mepc_address;
                                jump<=1'b1;
                                pc_jump<=csr_reg_read_data;
                                csr_reg_write_address<=mstatus_address;
                                csr_reg_write_data<={mstatus_data[31:8],mstatus_data[7:4],mstatus_data[7:4]};
                                csr_reg_write_enable<=1'b1;

                            end

                        endcase
                        // case(instruction[20])
                        //     1'b0:begin//ecall 环境调用 (Environment Call).//RaiseException(EnvironmentCall)
                                
                                
                        //     end
                        //     1'b1:begin//ebreak 环境断点 (Environment Breakpoint).//RaiseException(Breakpoint)
                                
                                
                        //     end
                        // endcase
                    end
                    3'b001:begin//csrrw 语法：csrrw rd, csr, rs1，作用是将csr寄存器的值读入rd，然后将rs1的值写入csr寄存器。
                        csr_reg_read_address<=csr_reg_address;
                        reg_write_address<=rd;
                        reg_write_data<=csr_reg_read_data;
                        reg_write_enable<=1'b1;
                        csr_reg_write_address<=csr_reg_address;
                        reg_read_a_address<=rs1;
                        csr_reg_write_data<=reg_read_a_data;
                        csr_reg_write_enable<=1'b1;
                    end
                    3'b010:begin//csrrs 语法：csrrs rd, csr, rs1，作用是将csr寄存器的值读入rd，然后将rs1的值与csr的值按位或后的结果写入csr寄存器。
                        csr_reg_read_address<=csr_reg_address;
                        reg_write_address<=rd;
                        reg_write_data<=csr_reg_read_data;
                        reg_write_enable<=1'b1;

                        reg_read_a_address<=rs1;
                        alu_opa<=reg_read_a_data;
                        alu_opb<=csr_reg_read_data;
                        alu_op<=alu_op_or;

                        csr_reg_write_address<=csr_reg_address;
                        csr_reg_write_data<=alu_result;
                        csr_reg_write_enable<=1'b1;
                    end
                    3'b011:begin//csrrc 语法：csrrc rd, csr, rs1，作用是将csr寄存器的值读入rd，然后将rs1的值与csr的值按位与后的结果写入csr寄存器。
                        csr_reg_read_address<=csr_reg_address;
                        reg_write_address<=rd;
                        reg_write_data<=csr_reg_read_data;
                        reg_write_enable<=1'b1;

                        reg_read_a_address<=rs1;
                        alu_opa<=reg_read_a_data;
                        alu_opb<=csr_reg_read_data;
                        alu_op<=alu_op_and;
                        
                        csr_reg_write_address<=csr_reg_address;
                        csr_reg_write_data<=alu_result;
                        csr_reg_write_enable<=1'b1;
                    end
                    3'b101:begin//csrrwi 语法：csrrwi rd, csr, imm，作用是将csr寄存器的值读入rd，然后将0扩展后的imm的值写入csr寄存器。
                        csr_reg_read_address<=csr_reg_address;
                        reg_write_address<=rd;
                        reg_write_data<=csr_reg_read_data;
                        reg_write_enable<=1'b1;
                        csr_reg_write_address<=csr_reg_address;
                        csr_reg_write_data<=imm_csr_zext;
                        csr_reg_write_enable<=1'b1;
                    end
                    3'b110:begin//csrrsi 语法：csrrsi rd, csr, imm，作用是将csr寄存器的值读入rd，然后将0扩展后的imm的值与csr的值按位或后的结果写入csr寄存器。
                        csr_reg_read_address<=csr_reg_address;
                        reg_write_address<=rd;
                        reg_write_data<=csr_reg_read_data;
                        reg_write_enable<=1'b1;

                        alu_opa<=imm_csr_zext;
                        alu_opb<=csr_reg_read_data;
                        alu_op<=alu_op_or;
                        
                        csr_reg_write_address<=csr_reg_address;
                        csr_reg_write_data<=alu_result;
                        csr_reg_write_enable<=1'b1;
                    end
                    3'b111:begin//csrrci 语法：csrrci rd, csr, imm，作用是将csr寄存器的值读入rd，然后将0扩展后的imm的值与csr的值按位与后的结果写入csr寄存器。
                        csr_reg_read_address<=csr_reg_address;
                        reg_write_address<=rd;
                        reg_write_data<=csr_reg_read_data;
                        reg_write_enable<=1'b1;

                        alu_opa<=imm_csr_zext;
                        alu_opb<=csr_reg_read_data;
                        alu_op<=alu_op_and;
                        
                        csr_reg_write_address<=csr_reg_address;
                        csr_reg_write_data<=alu_result;
                        csr_reg_write_enable<=1'b1;
                    end

                endcase
            end

            //default: ;
        endcase
    end

    register register_inst0(
        .clk(clk),
        .reg_write_address(reg_write_address),
        .reg_write_data(reg_write_data),
        .reg_write_enable((reg_write_enable&(phase==2'd3))),//phase==3再写
        .reg_read_a_address(reg_read_a_address),
        .reg_read_b_address(reg_read_b_address),
        .reg_read_a_data(reg_read_a_data),
        .reg_read_b_data(reg_read_b_data)
    );
    csr_reg csr_reg_inst0(
        .clk(clk),
        .csr_reg_write_address(csr_reg_write_address),
        .csr_reg_write_data(csr_reg_write_data),
        .csr_reg_write_enable((csr_reg_write_enable&phase==2'd3)),//phase==3再写
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
    rom rom_inst0(                       //vivado
        .clka(clk),
        .addra({17'b0,2'b0,pc_true[14:2]}),
        .douta(instruction)
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