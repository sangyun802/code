`include "opcodes.v"

module Control_unit(
    input [3:0] opcode,
    input [5:0] funct,
    output reg regdest,
    output reg jump,
    output reg alusrc1,
    output reg alusrc2,
    output reg regwrite,
    output reg [3:0]aluop,
    output reg mem_out
);
    always@(*) begin
        case(opcode)
            `OPCODE_RTYPE: begin
                regdest=1;
                alusrc1=0;
                alusrc2=0;
                jump=0;
                case(funct)
                    `FUNC_ADD:begin regwrite=1; aluop=`OP_ADD; mem_out=0; end
                    `FUNC_WWD:begin regwrite=0; aluop=`OP_ID; mem_out=1; end
                endcase
            end
            `OPCODE_ADI: begin
                aluop=`OP_ADD;
                regdest=0;
                alusrc1=0;
                alusrc2=1;
                regwrite=1;
                jump=0;
                mem_out=0;
            end
            `OPCODE_LHI: begin
                aluop=`OP_LLS;
                regdest=0;
                alusrc1=1;
                alusrc2=0;
                regwrite=1;
                jump=0;
                mem_out=0;
            end
            `OPCODE_JMP: begin
                regdest=0;
                alusrc1=0;
                alusrc2=0;
                regwrite=0;
                jump=1;
                mem_out=0;
            end
        endcase
    end
endmodule
