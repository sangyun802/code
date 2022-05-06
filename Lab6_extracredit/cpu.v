`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "opcodes.v"

module cpu(
        input Clk, 
        input Reset_N, 

	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_address, 
        inout [`WORD_SIZE-1:0] i_data, 

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [`WORD_SIZE-1:0] d_data, 

        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted
);
        // TODO : Implement your multi-cycle CPU!
        reg [`WORD_SIZE-1:0] num_inst;
        wire ALUsrcA, ALUsrcB, d_readM, d_writeM, i_readM, i_writeM, PCwrite, RegWrite, output_signal, flush, data_stall, jump_stall, IF_ID_no_btb, ID_EX_no_btb, EX_MEM_no_btb, branch_condition;
        wire[15:0] EX_MEM_rt_data;
        wire[1:0] RegDst, MEMtoReg, PCSrc, RegDst_output, rs, rt, EX_MEM_write_register, MEM_WB_write_register, forward_rs, forward_rt;
        wire[3:0] ALUop, opcode, ID_EX_opcode, EX_MEM_opcode, MEM_WB_opcode;
        wire[5:0] funct, ID_EX_funct, EX_MEM_funct, MEM_WB_funct;

        always@(*)begin
                if(!Reset_N)begin
                        num_inst<=0;
                end
        end
        always@(posedge Clk)begin
                if(Reset_N)begin
                        if(MEM_WB_opcode!=`OPCODE_Bubble)begin
                                num_inst<=num_inst+1;
                        end
                end
        end
        assign d_data=d_writeM?EX_MEM_rt_data:16'bz; 
        Datapath dp00(
                Clk,
                Reset_N,
                i_data,
                d_data,
                RegDst,
                ALUsrcA,
                ALUsrcB,
                ALUop,
                d_readM,
                d_writeM,
                PCwrite,
                MEMtoReg,
                RegWrite,
                PCSrc,
                output_signal, //WWD
                flush,
                data_stall,  //data hazard
                jump_stall,   //control hazard
                forward_rs,
                forward_rt,
                //to control unit
                opcode,
                ID_EX_opcode,
                EX_MEM_opcode,
                MEM_WB_opcode,
                IF_ID_no_btb,
                ID_EX_no_btb,
                EX_MEM_no_btb,
                funct,
                ID_EX_funct,
                EX_MEM_funct,
                MEM_WB_funct,
                branch_condition,
                RegDst_output, //wire from RegDst mux to EX_MEM_write_register
                rs,             //after decode
                rt,             //after decode
                EX_MEM_write_register,
                MEM_WB_write_register,
                //Instruction memory
                i_address,              //input address to Instruction memory
                //Data memory
                d_address,  //input address to Data memory
                EX_MEM_rt_data,     //input data to Data memory
                output_port
        );

        Control_unit cu00(
                Reset_N,
                opcode,
                ID_EX_opcode,
                EX_MEM_opcode,
                MEM_WB_opcode,
                funct,
                ID_EX_funct,
                EX_MEM_funct,
                MEM_WB_funct,
                branch_condition,
                IF_ID_no_btb,
                ID_EX_no_btb,
                EX_MEM_no_btb,
                RegDst_output, //wire from RegDst mux to EX_MEM_write_register
                rs,             //after decode
                rt,             //after decode
                EX_MEM_write_register,
                MEM_WB_write_register,
                i_readM,
                i_writeM,
                RegDst,
                ALUsrcA,
                ALUsrcB,
                ALUop,
                d_readM,
                d_writeM,
                PCwrite,
                MEMtoReg,
                RegWrite,
                PCSrc,
                is_halted,   //HLT
                output_signal, //WWD
                flush,
                data_stall,  //data hazard
                jump_stall   //control hazard
                forward_rs,
                forward_rt
        );

endmodule
