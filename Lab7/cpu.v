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
        wire ALUsrcA, ALUsrcB, PCwrite, RegWrite, output_signal, data_stall, jump_stall, d_mem_stall, i_mem_stall, flush, IF_ID_no_btb, ID_EX_no_btb, EX_MEM_no_btb, branch_condition;
        wire[15:0] EX_MEM_rt_data;
        wire[1:0] RegDst, MEMtoReg, PCsrc, RegDst_output, rs, rt, EX_MEM_write_register, MEM_WB_write_register;
        wire[3:0] ALUop, opcode, ID_EX_opcode, EX_MEM_opcode, MEM_WB_opcode;
        wire[5:0] funct, ID_EX_funct, EX_MEM_funct, MEM_WB_funct;

        reg i_mem_count, d_mem_count;

        //reset
        always@(*)begin
                if(!Reset_N)begin
                        num_inst<=0;
                        i_mem_count<=0;
                        d_mem_count<=0;
                end
        end

        always@(posedge Clk)begin
                if(Reset_N)begin
                        if(MEM_WB_opcode!=`OPCODE_Bubble)begin
                                num_inst<=num_inst+1;
                        end
                        //memory latency
                        if(i_readM|i_writeM)begin
                                if(!i_mem_count)begin
                                        i_mem_count<=i_mem_count+1;
                                end
                        end
                        if(d_readM|d_writeM)begin
                                if(d_mem_count)begin
                                        d_mem_count<=~d_mem_count;
                                end
                        end
                end
        end

        //memory latency
        always@(i_address)begin
                if(Reset_N)begin
                        if(i_readM|i_writeM)begin
                                if(i_mem_count)begin
                                        i_mem_count<=~i_mem_count;
                                end
                        end
                end
        end
        always@(posedge d_readM or posedge d_writeM)begin
                if(Reset_N)begin
                        if(!d_mem_count) begin
                                d_mem_count<=~d_mem_count;
                        end
                end
        end
        //input data to data memory
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
                PCsrc,
                output_signal, //WWD
                data_stall,  //data hazard
                jump_stall,   //control hazard
                d_mem_stall,
                i_mem_stall,
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
                output_port,
                flush
        );

        Control_unit cu00(
                Reset_N,
                Clk,
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
                flush,
                d_mem_count,
                i_mem_count,
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
                PCsrc,
                is_halted,   //HLT
                output_signal, //WWD
                data_stall,  //data hazard
                jump_stall,   //control hazard
                d_mem_stall,
                i_mem_stall
        );

endmodule