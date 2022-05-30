`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "opcodes.v"

module cpu(
        input Clk, 
        input Reset_N, 
        
        //DMA controller
        input DMA_begin,
        input DMA_end,
        input BR,
        output reg BG,
        output reg DMA_cmd,

	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_address, 
        inout [63:0] i_data, 

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [63:0] d_data, 

        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted
);
        // TODO : Implement your multi-cycle CPU!
        reg [`WORD_SIZE-1:0] num_inst;
        wire ALUsrcA, ALUsrcB, PCwrite, RegWrite, output_signal, data_stall, jump_stall, d_mem_stall, i_mem_stall, flush, IF_ID_no_btb, ID_EX_no_btb, EX_MEM_no_btb, branch_condition;
        wire i_readC, i_writeC, d_readC, d_writeC, i_hit, d_hit;
        wire[15:0] EX_MEM_rt_data, d_cache_address, PC, instruction, d_cache_data;
        wire[1:0] RegDst, MEMtoReg, PCsrc, RegDst_output, rs, rt, EX_MEM_write_register, MEM_WB_write_register;
        wire[3:0] ALUop, opcode, ID_EX_opcode, EX_MEM_opcode, MEM_WB_opcode;
        wire[5:0] funct, ID_EX_funct, EX_MEM_funct, MEM_WB_funct;
        wire[1:0] i_mem_count, d_mem_count;
        wire[15:0] d_mem_address;
        wire[63:0] d_mem_data;
        wire d_writem, d_readm;

        //if DMA access to memory make CPU not connect
        assign d_address=BG?16'bz:d_mem_address;
        assign d_writeM=BG?1'bz:d_writem;
        assign d_data=BG?64'bz:
                      d_writeM?d_mem_data:64'bz;
        assign d_mem_data=BG?64'bz:
                      d_readM?d_data:64'bz;
        assign d_readM=BG?1'b0:d_readm;

        //reset
        always@(*)begin
                if(!Reset_N)begin
                        num_inst=0;
                        BG=0;
                        DMA_cmd=0;
                end
        end

        always@(posedge Clk)begin
                if(Reset_N)begin
                        if(MEM_WB_opcode!=`OPCODE_Bubble)begin
                                num_inst<=num_inst+1;
                        end
                        //interrupt
                        if(DMA_begin) begin
                                DMA_cmd<=1;
                        end
                        
                        if((d_writeM|d_readM)&(d_mem_count!=2'b00)&(BG==0)) begin
                                BG<=0;
                        end
                        else begin
                                BG<=BR;
                        end
                end
        end
        //DMA interrupt
        always@(posedge DMA_end)begin
                DMA_cmd=0;
        end


        i_cache instruction_cache00(
                .clk(Clk),
                .reset_n(Reset_N),
                .jump_stall(jump_stall),
                .readC(i_readC),
                .writeC(i_writeC),
                .address(PC),
                .mem_data(i_data),
                .write_data(),
                .cache_data(instruction),
                .hit(i_hit),
                .readM(i_readM),
                .writeM(i_writeM),
                .mem_address(i_address),
                .mem_count(i_mem_count)
        );

        d_cache data_cache00(
                .clk(Clk),
                .reset_n(Reset_N),
                .readC(d_readC),
                .BG(BG),
                .writeC(d_writeC),
                .address(d_cache_address),
                .mem_data(d_mem_data),
                .write_data(EX_MEM_rt_data),
                .cache_data(d_cache_data),
                .hit(d_hit),
                .readM(d_readm),
                .writeM(d_writem),
                .mem_address(d_mem_address),
                .mem_count(d_mem_count)
        );

        Datapath dp00(
                Clk,
                Reset_N,
                instruction,
                d_cache_data,
                RegDst,
                ALUsrcA,
                ALUsrcB,
                ALUop,
                PCwrite,
                MEMtoReg,
                RegWrite,
                PCsrc,
                output_signal, //WWD
                data_stall,  //data hazard
                jump_stall,   //control hazard
                d_mem_stall,    //memory latency
                i_mem_stall,    //memory latency
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
                PC,              //input address to Instruction memory
                //Data memory
                d_cache_address,  //input address to Data memory
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
                i_readC,
                i_writeC,
                RegDst,
                ALUsrcA,
                ALUsrcB,
                ALUop,
                d_readC,
                d_writeC,
                PCwrite,
                MEMtoReg,
                RegWrite,
                PCsrc,
                is_halted,   //HLT
                output_signal, //WWD
                data_stall,  //data hazard
                jump_stall,   //control hazard
                d_mem_stall, //memory latency
                i_mem_stall //memory latency
        );

endmodule