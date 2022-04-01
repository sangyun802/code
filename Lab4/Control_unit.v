module Control_unit(
    input [3:0] opcode,
    output reg regdest,
    output reg jump,
    output reg alusrc,
    output reg regwrite,
    output reg [3:0]aluop
);
    always@(*) begin
        aluop=opcode;
        case(opcode)
            `OPCODE_RTYPE: begin
                regdest=1;
                alusrc=0;
                regwrite=1;
                jump=0;
            end
            `OPCODE_ADI: begin
                regdest=0;
                alusrc=1;
                regwrite=1;
                jump=0;
            end
            `OPCODE_LHI: begin
                regdest=0;
                alusrc=1;
                regwrite=1;
                jump=0;
            end
            `OPCODE_JMP: begin
                regdest=0;
                alusrc=0;
                regwrite=0;
                jump=1;
            end
        endcase
    end
endmodule
