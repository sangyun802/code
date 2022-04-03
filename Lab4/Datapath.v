
module Datapath(
    input [15:0] instruction,
    //from control units
    input regdest,
    input jump,
    input alusrc1,
    input alusrc2,
    input regwrite,
    input [3:0]aluop,
    input mem_out,

    input clk,
    input reset_n,

    output [15:0] output_port,  //output for alu
    output [3:0] opcode,         //input for control units
    output [5:0] funct,         //input for control units
    output [15:0] PC            //output for address
);
    reg[15:0] output_port;
    assign opcode=instruction[15:12];
    assign funct=instruction[5:0];

    wire[11:0] target_address=instruction[11:0];    //for jump
    wire [15:0] immediate_value;                    //for Itype value

    assign immediate_value={ {8{instruction[7]}}, instruction[7:0]};    //sign-extension

    PCcounter pc00(.jump(jump), .target_address(target_address), .clk(clk), .reset_n(reset_n), .PC(PC));

    wire[1:0] rs, rt, rd;
    wire[1:0] write_register;

    assign rs=instruction[11:10];
    assign rt=instruction[9:8];
    assign rd=instruction[7:6];
    assign write_register=(regdest)?rd:rt;         //RF write address input

    wire[15:0] read_data1, read_data2;
    wire[15:0] ALU_output;

    RF rf00(
        .write(regwrite),
        .clk(clk), 
        .reset_n(reset_n), 
        .read_register1(rs), 
        .read_register2(rt), 
        .write_register(write_register),
        .write_data(ALU_output), 
        .read_data1(read_data1), 
        .read_data2(read_data2)
    );
    
    wire [15:0] ALU_input1;
    wire [15:0] ALU_input2;
    assign ALU_input1=(alusrc1)?immediate_value:read_data1;     //distinguish LHI, else
    assign ALU_input2=(alusrc2)?immediate_value:read_data2;     //distinguish ADI, else

    ALU alu00(
        .A(ALU_input1), 
        .B(ALU_input2), 
        .Cin(1'b0), 
        .OP(aluop), 
        .C(ALU_output), 
        .Cout()
    );

    always@(posedge clk) begin
        output_port=(mem_out)?ALU_output:16'bz;         //output_port(synchronous)
    end


endmodule