`timescale 1ns/100ps
module Instruction_decoder(
    input[15:0] instruction,
    input clk,
    input reset_n,
    input IRWrite,
    output [3:0] opcode,
    output [1:0] rs,
    output [1:0] rt,
    output [1:0] rd,
    output [11:0] target_address,
    output [7:0] immediate,
    output [5:0] funct
);
    reg [15:0] current_instruction;

    assign opcode=current_instruction[15:12];
    assign rs=current_instruction[11:10];
    assign rt=current_instruction[9:8];
    assign rd=current_instruction[7:6];
    assign target_address=current_instruction[11:0];    //jump address
    assign immediate=current_instruction[7:0];          //for Itype
    assign funct= current_instruction[5:0];             //for Rtype
    
    always@(*)begin
        if(!reset_n) begin
            current_instruction=0;                  //reset
        end
    end

    always@(posedge clk)begin
        if(reset_n)begin
            if(IRWrite) begin
                current_instruction<=instruction;   //instruction fetch
            end
        end
    end
endmodule