module Control_unit(
    input reset_n,
    input[3:0] opcode,
    input[3:0] ID_EX_opcode,
    input[3:0] EX_MEM_opcode,
    input[3:0] MEM_WB_opcode,
    input[5:0] funct,
    input[5:0] ID_EX_funct,
    input[5:0] EX_MEM_funct,
    input[5:0] MEM_WB_funct,
    input branch_condition,
    input IF_ID_no_btb,
    input ID_EX_no_btb,
    input EX_MEM_no_btb,
    input[1:0] RegDst_output, //wire from RegDst mux to EX_MEM_write_register
    input[1:0] rs,             //after decode
    input[1:0] rt,             //after decode
    input[1:0] EX_MEM_write_register,
    input[1:0] MEM_WB_write_register,
    input flush,
    output i_readM,
    output i_writeM,
    output reg[1:0] RegDst,
    output reg ALUsrcA,
    output reg ALUsrcB,
    output reg [3:0] ALUop,
    output reg d_readM,
    output reg d_writeM,
    output reg PCwrite,
    output reg [1:0] MEMtoReg,
    output reg RegWrite,
    output reg [1:0] PCSrc,
    output reg is_halted,   //HLT
    output reg output_signal, //WWD
    //output flush,
    output reg data_stall,  //data hazard
    output reg jump_stall   //control hazard
);
    assign i_writeM=0;
    assign i_readM=1;
    reg PCwriteCond;
    wire branch_jump=PCwriteCond&branch_condition; //branch taken or not taken

    always@(*)begin
        is_halted=0;
        output_signal=0;
        case(ID_EX_opcode)
            `OPCODE_Rtype: begin
                ALUsrcA=0;
                ALUsrcB=0;
                case(ID_EX_funct)
                    `FUNC_ADD:begin
                        RegDst=2'b01;
                        ALUop=`OP_ADD;
                    end
                    `FUNC_AND:begin
                        RegDst=2'b01;
                        ALUop=`OP_AND;
                    end
                    `FUNC_NOT:begin
                        RegDst=2'b01;
                        ALUop=`OP_NOT;
                    end
                    `FUNC_ORR:begin
                        RegDst=2'b01;
                        ALUop=`OP_OR;
                    end
                    `FUNC_SHL:begin
                        RegDst=2'b01;
                        ALUop=`OP_LLS;
                    end
                    `FUNC_SHR:begin
                        RegDst=2'b01;
                        ALUop=`OP_ARS;
                    end
                    `FUNC_SUB:begin
                        RegDst=2'b01;
                        ALUop=`OP_SUB;
                    end
                    `FUNC_TCP:begin
                        RegDst=2'b01;
                        ALUop=`OP_TCP;
                    end
                    `FUNC_JRL:begin
                        RegDst=2'b10;
                    end
                endcase
            end
            `OPCODE_ADI: begin
                ALUsrcA=0;
                ALUsrcB=1;
                RegDst=2'b00;
                ALUop=`OP_ADD;
            end
            `OPCODE_BEQ: begin
                ALUsrcA=0;
                ALUsrcB=0;
                ALUop=`OP_BEQ;
            end
            `OPCODE_BGZ: begin
                ALUsrcA=0;
                ALUop=`OP_BGZ;
            end
            `OPCODE_BLZ: begin
                ALUsrcA=0;
                ALUop=`OP_BLZ;
            end
            `OPCODE_BNE: begin
                ALUsrcA=0;
                ALUsrcB=0;
                ALUop=`OP_BNE;
            end
            `OPCODE_JAL: begin
                RegDst=2'b10;
            end
            `OPCODE_LHI: begin
                ALUsrcA=1;
                ALUop=`OP_ID;
            end
            `OPCODE_LWD: begin
                ALUsrcA=0;
                ALUsrcB=1;
                RegDst=2'b00;
                ALUop=`OP_ADD;
            end
            `OPCODE_ORI: begin
                ALUsrcA=0;
                ALUsrcB=1;
                RegDst=2'b00;
                ALUop=`OP_OR;
            end
            `OPCODE_SWD: begin
                ALUsrcA=0;
                ALUsrcB=1;
                ALUop=`OP_ADD;
            end
        endcase
        casex(EX_MEM_opcode)
            `OPCODE_LWD: begin
                d_readM=1;
                d_writeM=0;
                PCwriteCond=0;
                PCSrc=2'b00;
            end
            `OPCODE_SWD:begin
                d_readM=0;
                d_writeM=1;
                PCwriteCond=0;
                PCSrc=2'b00;
            end
            4'b00xx:begin   //bne, beq, blz, bgz
                d_readM=0;
                d_writeM=0;
                PCwriteCond=1;
                PCSrc={1'b0, branch_jump};
            end
            `OPCODE_JMP:begin
                d_readM=0;
                d_writeM=0;
                PCwriteCond=0;
                PCSrc=2'b10;
            end
            `OPCODE_JAL:begin
                d_readM=0;
                d_writeM=0;
                PCwriteCond=0;
                PCSrc=2'b10;
            end
            `OPCODE_Rtype:begin
                case(EX_MEM_funct)
                    `FUNC_JPR:begin
                        d_readM=0;
                        d_writeM=0;
                        PCwriteCond=0;
                        PCSrc=2'b11;
                    end
                    `FUNC_JRL:begin
                        d_readM=0;
                        d_writeM=0;
                        PCwriteCond=0;
                        PCSrc=2'b11;
                    end
                    default:begin
                        d_readM=0;
                        d_writeM=0;
                        PCwriteCond=0;
                        PCSrc=2'b00;
                    end
                endcase
            end
            default:begin
                d_readM=0;
                d_writeM=0;
                PCwriteCond=0;
                PCSrc=2'b00;
            end
        endcase
        case(MEM_WB_opcode)
            `OPCODE_LWD:begin
                MEMtoReg=2'b10;
                RegWrite=1;
            end
            `OPCODE_JAL:begin
                MEMtoReg=2'b01;
                RegWrite=1;
            end
            `OPCODE_ADI:begin
                MEMtoReg=2'b00;
                RegWrite=1;
            end
            `OPCODE_ORI:begin
                MEMtoReg=2'b00;
                RegWrite=1;
            end
            `OPCODE_LHI:begin
                MEMtoReg=2'b00;
                RegWrite=1;
            end
            `OPCODE_Rtype:begin
                case(MEM_WB_funct)
                    `FUNC_JRL:begin
                        MEMtoReg=2'b01;
                        RegWrite=1;
                    end
                    `FUNC_WWD:begin
                        RegWrite=0;
                        output_signal=1;
                    end
                    `FUNC_HLT:begin
                        RegWrite=0;
                        is_halted=1;
                    end
                    `FUNC_JPR:begin
                        RegWrite=0;
                    end
                    default:begin
                        MEMtoReg=2'b00;
                        RegWrite=1;
                    end
                endcase
            end
            default:begin
                RegWrite=0;
                output_signal=0;
                is_halted=0;
            end
        endcase
    end

    //flush
    //assign flush=(~branch_jump)&PCwriteCond&(!jump_stall);
    //if jump_instruction exist in pipeline
    wire jump_instruction=(opcode==`OPCODE_JMP)|(opcode==`OPCODE_JAL)|(opcode==`OPCODE_BEQ)
                         |(opcode==`OPCODE_BGZ)|(opcode==`OPCODE_BLZ)|(opcode==`OPCODE_BNE)
                         |((opcode==`OPCODE_Rtype)&((funct==`FUNC_JPR)|(funct==`FUNC_JRL)));
    wire ID_EX_jump_instruction=(ID_EX_opcode==`OPCODE_JMP)|(ID_EX_opcode==`OPCODE_JAL)
                                |(ID_EX_opcode==`OPCODE_BEQ)|(ID_EX_opcode==`OPCODE_BGZ)|(ID_EX_opcode==`OPCODE_BLZ)|(ID_EX_opcode==`OPCODE_BNE)
                                |((ID_EX_opcode==`OPCODE_Rtype)&((ID_EX_funct==`FUNC_JPR)|(ID_EX_funct==`FUNC_JRL)));
    wire EX_MEM_jump_instruction=(EX_MEM_opcode==`OPCODE_JMP)|(EX_MEM_opcode==`OPCODE_JAL)
                                |(EX_MEM_opcode==`OPCODE_BEQ)|(EX_MEM_opcode==`OPCODE_BGZ)|(EX_MEM_opcode==`OPCODE_BLZ)|(EX_MEM_opcode==`OPCODE_BNE)
                                |((EX_MEM_opcode==`OPCODE_Rtype)&((EX_MEM_funct==`FUNC_JPR)|(EX_MEM_funct==`FUNC_JRL))); 
    
    wire use_rs=((opcode==`OPCODE_Rtype)&(funct!=`FUNC_HLT))
                |(opcode==`OPCODE_ADI)|(opcode==`OPCODE_ORI)|(opcode==`OPCODE_LWD)|(opcode==`OPCODE_SWD)
                |(opcode==`OPCODE_BEQ)|(opcode==`OPCODE_BNE)|(opcode==`OPCODE_BLZ)|(opcode==`OPCODE_BGZ);
    wire use_rt=((opcode==`OPCODE_Rtype)&((funct==`FUNC_ADD)|(funct==`FUNC_SUB)|(funct==`FUNC_AND)|(funct==`FUNC_ORR)))
                |(opcode==`OPCODE_SWD)
                |(opcode==`OPCODE_BEQ)|(opcode==`OPCODE_BNE);
    
    wire register_write_inst_EX=((ID_EX_opcode==`OPCODE_Rtype)&((ID_EX_funct!=`FUNC_WWD)&(ID_EX_funct!=`FUNC_HLT)&(ID_EX_funct!=`FUNC_JPR)))
                               |(ID_EX_opcode==`OPCODE_ADI)|(ID_EX_opcode==`OPCODE_JAL)|(ID_EX_opcode==`OPCODE_LHI)|(ID_EX_opcode==`OPCODE_LWD)|(ID_EX_opcode==`OPCODE_ORI);
    wire register_write_inst_MEM=((EX_MEM_opcode==`OPCODE_Rtype)&((EX_MEM_funct!=`FUNC_WWD)&(EX_MEM_funct!=`FUNC_HLT)&(EX_MEM_funct!=`FUNC_JPR)))
                                |(EX_MEM_opcode==`OPCODE_ADI)|(EX_MEM_opcode==`OPCODE_JAL)|(EX_MEM_opcode==`OPCODE_LHI)|(EX_MEM_opcode==`OPCODE_LWD)|(EX_MEM_opcode==`OPCODE_ORI);
    wire register_write_inst_WB=((MEM_WB_opcode==`OPCODE_Rtype)&((MEM_WB_funct!=`FUNC_WWD)&(MEM_WB_funct!=`FUNC_HLT)&(MEM_WB_funct!=`FUNC_JPR)))
                               |(MEM_WB_opcode==`OPCODE_ADI)|(MEM_WB_opcode==`OPCODE_JAL)|(MEM_WB_opcode==`OPCODE_LHI)|(MEM_WB_opcode==`OPCODE_LWD)|(MEM_WB_opcode==`OPCODE_ORI);
    
    wire no_btb=(IF_ID_no_btb&jump_instruction)|(ID_EX_no_btb&ID_EX_jump_instruction)|(EX_MEM_no_btb&EX_MEM_jump_instruction);
    //stall
    always@(*)begin
        //avoid control hazard
        if(no_btb) begin
            jump_stall=1;
        end
        else begin
            jump_stall=0;
        end
        //avoid data hazard
        if(use_rs&register_write_inst_EX&(rs==RegDst_output))begin
            data_stall=1;
        end
        else if(use_rt&register_write_inst_EX&(rt==RegDst_output))begin
            data_stall=1;
        end
        else if(use_rs&register_write_inst_MEM&(rs==EX_MEM_write_register))begin
            data_stall=1;
        end
        else if(use_rt&register_write_inst_MEM&(rt==EX_MEM_write_register))begin
            data_stall=1;
        end
        else if(use_rs&register_write_inst_WB&(rs==MEM_WB_write_register))begin
            data_stall=1;
        end
        else if(use_rt&register_write_inst_WB&(rt==MEM_WB_write_register))begin
            data_stall=1;
        end
        else begin
            data_stall=0;
        end

        if((((IF_ID_no_btb&jump_instruction)|(ID_EX_no_btb&ID_EX_jump_instruction))|data_stall)&!flush)begin
            PCwrite=0;
        end
        else begin
            PCwrite=1;
        end
        if(!reset_n)begin
            data_stall=0;
            jump_stall=0;
        end
    end
endmodule