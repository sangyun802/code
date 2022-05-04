`timescale 1ns/100ps
`include "opcodes.v"

`define IF 3'b000       //instruction fetch
`define ID 3'b001       //instruction decoding
`define EX 3'b010       //execution
`define WB 3'b011       //write back
`define MEM 3'b110      //memory
`define RESET 3'b111    //reset

module Control_unit(
    input [3:0] opcode,
    input [5:0] funct,
    input clk,
    input reset_n,
    output reg PCWriteCond, //bne, beq, bgz, blz
    output reg PCWrite,     //for PC update
    output reg IorD,        //1: LWD, SWD   0: else
    output reg MemRead,     //readm
    output reg MemWrite,    //writem
    output reg [1:0] MemtoReg,
    output reg IRWrite,     //instruction fetch
    output reg [1:0]RegDst,
    output reg Regwrite,
    output reg [1:0]ALUsrcA,
    output reg [1:0]ALUsrcB,
    output reg [3:0]ALUOP,
    output reg [1:0] PCSource,  //determine next PC
    output reg Memout,          //WWD
    output reg is_halted,       //HLT
    output[2:0] current_state
);
    reg[2:0] current_state, next_state;
    
    always@(*) begin
        //reset
        if(!reset_n)begin
            current_state=`RESET;
            next_state=`RESET;
        end
    end
    
    always@(*) begin
        if(reset_n) begin
            case(current_state)
                `RESET: next_state=`IF;
                `IF: next_state=`ID;
                `ID: begin
                    case(opcode)
                        `OPCODE_RType: begin
                            casex(funct)
                                6'b01xxxx: next_state=`IF;  //WWD, JPR, JRL, HLT
                                default: next_state=`EX;
                            endcase
                        end
                        `OPCODE_JAL: next_state=`IF;
                        `OPCODE_JMP: next_state=`IF;
                        default: next_state=`EX;
                    endcase
                end
                `EX: begin
                    casex(opcode)
                        `OPCODE_LWD: next_state=`MEM;
                        `OPCODE_SWD: next_state=`MEM;
                        4'b00xx: next_state=`IF; //BNE, BEQ, BGZ, BLZ
                        default: next_state=`WB;
                    endcase
                end
                `MEM: begin
                    case(opcode)
                        `OPCODE_SWD: next_state=`IF;
                        `OPCODE_LWD: next_state=`WB;
                    endcase
                end
                `WB: next_state=`IF;
            endcase
            case(current_state)
                `RESET: begin
                    //reset
                    IRWrite=0;
                    MemRead=0;
                    MemWrite=0;
                    IorD=0;
                    Regwrite=0;
                    PCWrite=0;
                    PCWriteCond=0;
                    Memout=0;
                end
                `IF: begin //instruction fetch & PC<=PC+1
                    IRWrite=1; 
                    MemRead=1; 
                    MemWrite=0; 
                    IorD=0; 
                    Regwrite=0;
                    PCWrite=1;
                    ALUOP=`OP_ADD;      //PC+1
                    ALUsrcA=2'b00;      //PC
                    ALUsrcB=2'b01;      //1
                    PCSource=2'b00;
                    PCWriteCond=0;
                    Memout=0;
                    is_halted=0;
                end
                `ID: begin //ALUout<=PC+sign-extended_immediate
                    PCWriteCond=0;
                    ALUOP=`OP_ADD;
                    ALUsrcA=2'b00;      //PC
                    ALUsrcB=2'b10;      //signextend immediate
                    MemWrite=0;
                    IRWrite=0;
                    MemRead=0;
                    IorD=0;             //don't care
                    case(opcode)    //determine jump, WWD, HLT output
                        `OPCODE_RType: begin
                            case(funct)
                            `FUNC_JPR: begin
                                PCWrite=1; 
                                RegDst=2'b01; 
                                Regwrite=0;
                                PCSource=2'b11;     //jump address(rs)
                                is_halted=0;
                                Memout=0;
                                MemtoReg=2'b00;
                            end 
                            `FUNC_JRL: begin 
                                PCWrite=1;
                                RegDst=2'b10;   //write register $2;
                                Regwrite=1;
                                PCSource=2'b11; //jump address(rs)
                                is_halted=0;
                                Memout=0;
                                MemtoReg=2'b10;
                            end
                            `FUNC_HLT: begin
                                RegDst=2'b01; 
                                Regwrite=0;
                                PCSource=2'b00;
                                is_halted=1;
                                Memout=0;
                                PCWrite=0;
                                MemtoReg=2'b00;
                            end
                            `FUNC_WWD: begin
                                RegDst=2'b01; 
                                Regwrite=0;
                                PCSource=2'b00;
                                is_halted=0;
                                Memout=1;
                                PCWrite=0;
                                MemtoReg=2'b00;
                            end 
                            default: begin 
                                RegDst=2'b01; 
                                Regwrite=0;
                                PCSource=2'b00;
                                is_halted=0;
                                Memout=0;
                                PCWrite=0;
                                MemtoReg=2'b00;
                            end 
                            endcase
                        end
                        `OPCODE_JMP: begin
                            PCWrite=1;
                            RegDst=2'b00; 
                            Regwrite=0;
                            PCSource=2'b01; //jump address
                            is_halted=0;
                            Memout=0;
                            MemtoReg=2'b00;
                        end
                        `OPCODE_JAL: begin
                            PCWrite=1;
                            RegDst=2'b10; 
                            Regwrite=1;
                            PCSource=2'b01; //jump address
                            is_halted=0;
                            Memout=0;
                            MemtoReg=2'b10;
                        end
                        default: begin  //Itype
                            PCWrite=0;
                            RegDst=2'b00; 
                            Regwrite=0;
                            PCSource=2'b00;
                            is_halted=0;
                            Memout=0;
                            MemtoReg=2'b00;
                        end
                    endcase
                end
                `EX: begin
                    IorD=0;         //don't care
                    MemRead=0;
                    MemWrite=0;
                    MemtoReg=2'b00; //don't care
                    IRWrite=0;
                    Regwrite=0;
                    PCWrite=0;
                    is_halted=0;
                    Memout=0;
                    RegDst=2'b00; //don't care
                    case(opcode)
                        `OPCODE_RType:begin
                            PCWriteCond=0;
                            ALUsrcA=2'b01;      //rs
                            ALUsrcB=2'b00;      //rt
                            PCSource=2'b00;     //don't care
                            case(funct)
                                //determine ALU operation by function
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
                            ALUsrcA=2'b01;      //rs
                            ALUsrcB=2'b10;      //sign extend
                            PCSource=2'b00;     //don't care
                            ALUOP=`OP_ADD;
                        end
                        `OPCODE_ORI: begin
                            PCWriteCond=0;
                            ALUsrcA=2'b01;
                            ALUsrcB=2'b10;
                            PCSource=2'b00;     //don't care
                            ALUOP=`OP_OR;
                        end
                        `OPCODE_LHI: begin
                            PCWriteCond=0;
                            ALUsrcA=2'b10;      //shift left immediate
                            ALUsrcB=2'b01;      //don't care
                            PCSource=2'b00;     //don't care
                            ALUOP=`OP_ID;
                        end
                        `OPCODE_LWD: begin
                            PCWriteCond=0;
                            ALUsrcA=2'b01;      //rs
                            ALUsrcB=2'b10;      //signextend
                            PCSource=2'b00;     //don't care
                            ALUOP=`OP_ADD;
                        end
                        `OPCODE_SWD: begin
                            PCWriteCond=0;
                            ALUsrcA=2'b01;      //rs
                            ALUsrcB=2'b10;      //signextend
                            PCSource=2'b00;     //don't care
                            ALUOP=`OP_ADD;
                        end
                        `OPCODE_BNE: begin
                            PCWriteCond=1;
                            ALUsrcA=2'b01;      //rs
                            ALUsrcB=2'b00;      //rt
                            PCSource=2'b10;
                            ALUOP=`OP_BNE;
                        end
                        `OPCODE_BEQ: begin
                            PCWriteCond=1;
                            ALUsrcA=2'b01;      //rs
                            ALUsrcB=2'b00;      //rt
                            PCSource=2'b10;
                            ALUOP=`OP_BEQ;
                        end
                        `OPCODE_BGZ: begin
                            PCWriteCond=1;
                            ALUsrcA=2'b01;      //rs
                            ALUsrcB=2'b00;      //rt
                            PCSource=2'b10;
                            ALUOP=`OP_BGZ;
                        end
                        `OPCODE_BLZ: begin
                            PCWriteCond=1;
                            ALUsrcA=2'b01;      //rs
                            ALUsrcB=2'b00;      //rt
                            PCSource=2'b10;
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
                    Regwrite=1;
                    is_halted=0;
                    Memout=0;
                    case(opcode)
                        `OPCODE_RType: RegDst=2'b01;
                        default: RegDst=2'b00;
                    endcase
                    if(opcode==`OPCODE_LWD) begin
                        MemtoReg=2'b01;
                    end
                    else begin
                        MemtoReg=2'b00;
                    end
                end
                `MEM: begin
                    PCWriteCond=0;
                    PCWrite=0;
                    IorD=1;
                    IRWrite=0;
                    RegDst=2'b00;   //don't care
                    Regwrite=0;
                    MemtoReg=2'b00; //don't care
                    is_halted=0;
                    Memout=0;
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
            endcase
        end
    end
    

    always@(posedge clk) begin
        //state update
        if(reset_n)begin
            current_state<=next_state;
        end
    end
endmodule
