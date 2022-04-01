module Datapath(
    input [15:0] current_address,
    input [15:0] instruction,
    input regdest,
    input jump,
    input alusrc,
    input regwrite,
    input [3:0]aluop,
    input clk,
    input reset_n,
    output [15:0] next_address,
    output [15:0] output_port,
    output [3:0] opcode
);
    assign opcode=instruction[15:12];

    wire[11:0] target_address=instruction[11:0];
    wire[5:0] funct=instruction[5:0];
    wire [15:0] immediate_value;

    assign immediate_value={8{instruction[7]}, instruction[7:0]};

    PCcounter pc00(current_address,jump, target_address, next_address);

    wire[1:0] rs, rt, rd;
    wire[1:0] write_register;

    assign rs=instruction[11:10];
    assign rt=instruction[9:8];
    assign rd=instruction[7:6];
    assign write_register=(regdest)?rd:rt;

    wire[15:0] read_data1, read_data2;
    wire[15:0] calculate_output;

    RF rf00(regwrite, clk, reset_n, rs, rt, write_register, calculate_output, read_data1, read_data2);
    
    wire [15:0] ALU_input2;
    assign ALU_input2=(alusrc)?immediate_value:read_data2;

    ALU alu00(aluop, funct, read_data1, ALU_input2, output_port, calculate_output);


endmodule