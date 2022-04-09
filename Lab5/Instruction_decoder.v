module Instruction_decoder(
    input[16:0] instruction,
    //input clk,
    input IRWrite,
    output reg [3:0] opcode,
    output reg [1:0] rs,
    output reg [1:0] rt,
    output reg [1:0] rd,
    output reg [11:0] target_address,
    output reg [7:0] immediate
);
    always@(*)begin
        if(IRWrite) begin
            opcode=instruction[15:12];
            rs=instruction[11:10];
            rt=instruction[9:8];
            rd=instruction[7:6];
            target_address=instruction[11:0];
            immediate=instruction[7:0];
        end
    end
endmodule