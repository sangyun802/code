`include "opcodes.v"

`define IF 3'b000
`define ID 3'b001
`define EX 3'b010
`define WB 3'b011
`define MEM 3'b110

module Control_unit(
    input [3:0] opcode,
    input [5:0] funct,
    input clk,
    input reset_n;
    output reg PCWriteCond,
    output reg PCWrite,
    output reg IorD,
    output reg MemRead,
    output reg MemWrite,
    output reg MemtoReg,
    output reg IRWrite,
    output reg [1:0]RegDst,
    output reg Regwrite,
    output reg [1:0]ALUsrcA,
    output reg [1:0]ALUsrcB,
    output reg [3:0]ALUOP,
    output reg [1:0] PCSource
);
    reg[2:0] current_state, next_state;
    always@(*) begin
        case(current_state):
            `IF: next_state=`ID;
            `ID: begin
                case(opcode):
                    `OPCODE_RType: begin
                        casex(funct):
                            6'b01xxx: next_state=`ID;
                            default: next_state=`EX;
                        endcase
                    end
                    `OPCODE_JAL: next_state=`ID;
                    `OPCODE_JMP: next_state=`ID;
                    default: next_state=`EX;
                endcase
            end
            `EX: begin
                case(opcode):
                    `OPCODE_RType: begin
                        casex(funct):
                            6'b000xx: next_state=`ID;
                            default: next_state=`WB;
                        endcase
                    end
                    `OPCODE_ADI: next_state=`WB;
                    `OPCODE_ORI: next_state=`WB;
                    `OPCODE_LHI: next_state=`WB;
                    default: next_state=`MEM;
                endcase
            end
            `MEM: begin
                case(opcode):
                    `OPCODE_SWD: next_state=`ID;
                    `OPCODE_LWD: next_state=`EX;
                endcase
            end
            `WB: next_state=`ID;
            end
        endcase
        case(current_state)
            `IF: begin IRWrite=1; MemRead=1; MemWrite=0; IorD=0; end
            `ID: begin
                PCWriteCond=0;
                ALUOP=`OP_ADD;
                ALUsrcA=2'b00;
                ALUsrcB=2'b01;
                PCWrite=1;
                IorD=0;
                MemRead=0;
                MemWrite=0;
                MemtoReg=0;
                IRWrite=0;
                case(opcode):
                    `OPCODE_RType: begin
                        case(funct):
                        `FUNC_JPR: begin 
                            RegDst=2'b01; 
                            Regwrite=0;
                            PCSource=2'b11;
                        end 
                        `FUNC_JRL: begin 
                            RegDst=2'b10;   //write register $2;
                            Regwrite=1;
                            PCSource=2'b11;
                        end
                        /*`FUNC_HLT: begin 
                            ALUOP=`OP_ADD; 
                            ALUsrcA=2'b00; 
                            ALUsrcB=2'b01; 
                            PCWrite=1; 
                            RegDst=1; 
                            PCSource=2'b00; 
                            IorD=0;
                            MemRead=0; 
                            MemWrite=0; 
                            MemtoReg=0;
                            IRWrite=0;
                            Regwrite=0;
                        end*/
                        default: begin 
                            RegDst=2'b01; 
                            Regwrite=0;
                            PCSource=2'b00;
                        end
                        endcase
                    end
                    `OPCODE_JMP: begin
                        RegDst=2'b00; 
                        Regwrite=0;
                        PCSource=2'b01;
                    end
                    `OPCODE_JAL: begin
                        RegDst=2'b10; 
                        Regwrite=1;
                        PCSource=2'b01;
                    end
                    `default: begin  //Itype
                        RegDst=2'b00; 
                        Regwrite=0;
                        PCSource=2'b00;
                    end
                endcase
            end
            `EX: begin
                IorD=0;
                MemRead=0;
                MemWrite=0;
                MemtoReg=0;
                IRWrite=0;
                Regwrite=0;
                PCWrite=0;
                case(opcode):
                    `OPCODE_RType:begin
                        PCWriteCond=0;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b00;
                        PCSource=2'b00;
                        RegDst=2'b01;
                        case(funct):
                            `FUNC_ADD: ALUOP=`OP_ADD;
                            `FUNC_SUB: ALUOP=`OP_SUB;
                            `FUNC_AND: ALUOP=`OP_AND;
                            `FUNC_ORR: ALUOP=`OP_OR;
                            `FUNC_NOT: ALUOP=`OP_NOT;
                            `FUNC_TCP: ALUOP=`OP_TCP;
                            `FUNC_SHL: ALUOP=`OP_LLS;
                            `FUNC_SHR: ALUOP=`OP_ARS;
                        endcase
                    end
                    `OPCODE_ADI: begin
                        PCWriteCond=0;
                        PCWrite=0;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b10;
                        PCSource=2'b00;
                        RegDst=2'b00;
                        ALUOP=`OP_ADD;
                    end
                    `OPCODE_ORI: begin
                        PCWriteCond=0;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b10;
                        PCSource=2'b00;
                        RegDst=2'b00;
                        ALUOP=`OP_OR;
                    end
                    `OPCODE_LHI: begin
                        PCWriteCond=0;
                        ALUsrcA=2'b10;
                        ALUsrcB=2'b01;  //Don't care
                        PCSource=2'b00;
                        RegDst=2'b00;
                        ALUOP=`OP_ID;
                    end
                    `OPCODE_LWD: begin
                        PCWriteCond=0;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b10;
                        PCSource=2'b00;
                        RegDst=2'b00;
                        ALUOP=`OP_ADD;
                    end
                    `OPCODE_SWD: begin
                        PCWriteCond=0;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b10;
                        PCSource=2'b00;
                        RegDst=2'b00;
                        ALUOP=`OP_ADD;
                    end
                    `OPCODE_BNE: begin
                        PCWriteCond=1;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b10;
                        PCSource=2'b10;
                        RegDst=2'b00;
                        ALUOP=`OP_BNE;
                    end
                    `OPCODE_BEQ: begin
                        PCWriteCond=1;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b10;
                        PCSource=2'b10;
                        RegDst=2'b00;
                        ALUOP=`OP_BEQ;
                    end
                    `OPCODE_BGZ: begin
                        PCWriteCond=1;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b10;
                        PCSource=2'b10;
                        RegDst=2'b00;
                        ALUOP=`OP_BGZ;
                    end
                    `OPCODE_BLZ: begin
                        PCWriteCond=1;
                        ALUsrcA=2'b01;
                        ALUsrcB=2'b10;
                        PCSource=2'b10;
                        RegDst=2'b00;
                        ALUOP=`OP_BLZ;
                    end
                endcase
            end
            `WB: begin
                PCWriteCond=0;
                PCWrite=0;
                IorD=0;
                MemRead=0;
                MemWrite=0;
                IRWrite=0;
                RegDst=2'b00;
                Regwrite=1;
                if(opcode=`OPCODE_LWD) begin
                    MemtoReg=1;
                end
                else begin
                    MemtoReg=0;
                end
            end
            `MEM: begin
                PCWriteCond=0;
                PCWrite=0;
                IorD=1;
                IRWrite=0;
                RegDst=2'b00;
                Regwrite=1;
                MemtoReg=0;
                case(opcode)
                    `OPCODE_LWD:begin 
                        MemRead=1;
                        MemWrite=0;
                    end
                    `OPCODE_SWD:begin
                        MemRead=0;
                        MemWrite=1;
                    end
                endcase
            end
    end
    
    always@(*) begin
        if(!reset_n)begin
            current_state=`ID;
            next_state=`ID;
        end
    end

    always@(posedge clk) begin
        if(reset_n)begin
            current_state<=next_state;
        end
    end
endmodule
