`include "opcodes.v"
module ALU(
    input [15:0] A,     //input1
    input [15:0] B,     //input2
    input Cin,
    input [3:0] OP,     //opcode
    output [15:0] ALU_result,    //output
    output branch_condition, //output
    output Cout
);
    reg [15:0] ALU_result;
    reg Cout, branch_condition;
    always@(*) begin
        //initialize Cout=0
        Cout=0;
        branch_condition=0;
        case(OP)
            
            `OP_ADD:{Cout, ALU_result}=A+B+Cin;    //add (ADD, ADI, LWD, SWD, PC calculate)
            `OP_SUB:{Cout, ALU_result}=A-B-Cin;    //subtract(SUB)
            
            `OP_ID:ALU_result=A;     //Identity (LHI))
                        
            `OP_BNE: branch_condition=(A!=B);  //BNE
            `OP_BEQ: branch_condition=(A==B);  //BEQ
            `OP_BGZ: branch_condition=($signed(A)>0); //BGZ
            `OP_BLZ: branch_condition=($signed(A)<0); //BLZ

            `OP_TCP: ALU_result=~A+1;    //TCP

            `OP_NOT:ALU_result=~A;       //not(NOT)
            `OP_AND:ALU_result=A&B;      //and(AND)
            `OP_OR:ALU_result=A|B;       //or(ORR, ORI)
            
            `OP_ARS:ALU_result=$signed(A)>>>1;   //arithmetic right shifting(SHR)
            `OP_LLS:ALU_result=A<<1;             //logical leftshifting(SHL)
        endcase
    end
endmodule