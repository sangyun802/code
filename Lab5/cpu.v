`timescale 1ns/100ps

`include "opcodes.v"
`include "constants.v"

module cpu (
    output readM, // read from memory
    output writeM, // write to memory
    output [`WORD_SIZE-1:0] address, // current address for data
    inout [`WORD_SIZE-1:0] data, // data being input or output
    input inputReady, // indicates that data is ready from the input port
    input reset_n, // active-low RESET signal
    input clk, // clock signal
    
    // for debuging/testing purpose
    output [`WORD_SIZE-1:0] num_inst, // number of instruction during execution
    output [`WORD_SIZE-1:0] output_port, // this will be used for a "WWD" instruction
    output is_halted // 1 if the cpu is halted
);
    // ... fill in the rest of the code
    wire PCWriteCond, PCWrite, IorD, IRWrite, Regwrite, Memout;
    wire[1:0] RegDst, ALUsrcA, ALUsrcB, PCSource, MemtoReg;
    wire[3:0] ALUOP, opcode; 
    wire[5:0] funct;
    wire[2:0] current_state;

    reg[15:0] instruction, Memreaddata, num_inst;
    wire[15:0] Memwritedata;

    always@(*)begin
        if(!reset_n) begin
            instruction=16'h9000;
            num_inst=-1;
        end
    end

    always@(posedge clk)begin
        if(reset_n) begin
            if(current_state==`IF) begin
                num_inst<=num_inst+1;
            end
        end
    end

    always@(posedge inputReady)begin
        if(reset_n) begin
            instruction<=data;
            Memreaddata<=data;
        end
    end
    
    assign data=writeM?Memwritedata:16'bz;
    
    Datapath Dp00(instruction, Memreaddata, clk, reset_n, PCWriteCond, PCWrite, IorD, readM, writeM, MemtoReg, IRWrite, RegDst, Regwrite, ALUsrcA, ALUsrcB, ALUOP, PCSource, Memout, output_port, opcode, funct, address, Memwritedata);
    Control_unit Cu00(opcode, funct, clk, reset_n, PCWriteCond, PCWrite, IorD, readM, writeM, MemtoReg, IRWrite, RegDst, Regwrite, ALUsrcA, ALUsrcB, ALUOP, PCSource, Memout, is_halted, current_state);
endmodule
