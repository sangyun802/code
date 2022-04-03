`include "opcodes.v"
module ALU(
    input [15:0] A,     //input1
    input [15:0] B,     //input2
    input Cin,
    input [3:0] OP,     //opcode
    output [15:0] C,    //output
    output Cout
);
    reg [15:0] C;
    reg Cout;
    always@(*) begin
        //initialize Cout=0
        Cout=0;
        case(OP)
            //Arithmetic
            `OP_ADD:{Cout, C}=A+B+Cin;  //add(by concatenation)
            //`OP_SUB:{Cout, C}=A-B-Cin;    //subtract(ternary operator& concatenation)
            //Bitwise Boolean operation
            `OP_ID:C=A;     //Identity
            //`OP_NAND:C=~(A&B);  //nand
            //`OP_NOR:C=~(A|B);   //nor
            //`OP_XNOR:C=A~^B;    //xnor
            //`OP_NOT:C=~A;       //not
            //`OP_AND:C=A&B;      //and
            //`OP_OR:C=A|B;       //or
            //`OP_XOR:C=A^B;      //xor
            //Shifting
            //`OP_LRS:C=A>>1;             //logical right shifting
            //`OP_ARS:C=$signed(A)>>>1;   //arithmetic right shifting
            //`OP_RR:C={A[0], A[15:1]};   //rotate right
            `OP_LLS:C=A<<8;             //logical leftshifting
            //`OP_ALS:C=A<<<1;            //arithmetic left shifting
            //`OP_RL:C={A[14:0], A[15]};  //rotate left
        endcase
    end
endmodule