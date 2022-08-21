module alu (
    input clk,
    input [2:0] phase,
    input [4:0] op,
    input [31:0] opa,
    input [31:0] opb,
    output reg [31:0] alu_result,
    output wire alu_result_is_zero
);

localparam alu_op_add=5'd0,alu_op_slti=5'd1,alu_op_sltu=5'd2,
    alu_op_xori=5'd3,alu_op_ori=5'd4,alu_op_andi=5'd5,alu_op_slli=5'd6,alu_op_srli=5'd7,
    alu_op_srai=5'd8,alu_op_sub=5'd9,alu_op_sll=5'd10,alu_op_slt=5'd11,
    alu_op_xor=5'd13,alu_op_srl=5'd14,alu_op_sra=5'd15,alu_op_or=5'd16,alu_op_and=5'd17,
    alu_op_beq=5'd18,alu_op_bne=5'd19,alu_op_blt=5'd20,alu_op_bge=5'd21,alu_op_bltu=5'd22,
    alu_op_bgeu=5'd23;

always@(posedge clk)begin
    if(phase==3'd2)begin
        case(op)
            alu_op_add:begin//auipc opa:pc opb:immediate<<12
                alu_result<=opa+opb;
            end
            alu_op_slti,alu_op_slt:begin
                alu_result<=($signed(opa)<$signed(opb));
            end
            alu_op_sltu:begin
                alu_result<=($unsigned(opa)<$unsigned(opb));
            end
            alu_op_xori,alu_op_xor:begin
                alu_result<=opa^opb;
            end
            alu_op_ori,alu_op_or:begin
                alu_result<=opa|opb;
            end
            alu_op_andi,alu_op_and:begin
                alu_result<=opa&opb;
            end
            alu_op_slli,alu_op_sll:begin
                alu_result<=opa<<opb;
            end
            alu_op_srli,alu_op_srl:begin
                alu_result<=opa>>$unsigned(opb);
            end
            alu_op_srai,alu_op_sra:begin
                alu_result<=($signed(opa))>>>opb;
            end
            alu_op_sub:begin
                alu_result<=opa-opb;
            end
            alu_op_beq:begin
                alu_result<=opa==opb;
            end
            alu_op_bne:begin
                alu_result<=$signed(opa)!=$signed(opb);
            end
            alu_op_blt:begin
                alu_result<=$signed(opa)<$signed(opb);
            end
            alu_op_bge:begin
                alu_result<=($signed(opa)>$signed(opb))||($signed(opb)==$signed(opb));
            end
            alu_op_bltu:begin
                alu_result<=$unsigned(opa)<$unsigned(opb);
            end
            alu_op_bgeu:begin
                alu_result<=($unsigned(opa)>$unsigned(opb))||($unsigned(opa)==$unsigned(opb));
            end
        endcase
    end
    else begin
        alu_result<=alu_result;
    end
end

endmodule //alu