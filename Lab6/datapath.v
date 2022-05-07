module Datapath(
    input clk,
    input reset_n,
    input [15:0] Imemdata,
    input [15:0] Dmemdata,
    //from control unit
    input[1:0] RegDst,
    input ALUsrcA,
    input ALUsrcB,
    input [3:0] ALUop,
    input d_readM,
    input d_writeM,
    input PCwrite,
    input [1:0] MEMtoReg,
    input RegWrite,
    input [1:0] PCsrc,
    input output_signal, //WWD
    input data_stall,  //data hazard
    input jump_stall,   //control hazard
    //to control unit
    output[3:0] opcode, //afterdecode
    output[3:0] ID_EX_opcode,
    output[3:0] EX_MEM_opcode,
    output[3:0] MEM_WB_opcode,
    output IF_ID_no_btb,
    output ID_EX_no_btb,
    output EX_MEM_no_btb,
    output[5:0] funct,          //after decode
    output[5:0] ID_EX_funct,
    output[5:0] EX_MEM_funct,
    output[5:0] MEM_WB_funct,
    output branch_condition,
    output[15:0] RegDst_output, //wire from RegDst mux to EX_MEM_write_register
    output[1:0] rs,             //after decode
    output[1:0] rt,             //after decode
    output[1:0] EX_MEM_write_register,
    output[1:0] MEM_WB_write_register,
    //Instruction memory
    output[15:0] current_PC,              //input address to Instruction memory
    //Data memory
    output[15:0] EX_MEM_ALUresult,  //input address to Data memory
    output[15:0] EX_MEM_rt_data,     //input data to Data memory
    output[15:0] output_port,       //WWD
    output flush
);
reg[15:0] output_port;

//buffer for stage
reg [3:0] ID_EX_opcode, EX_MEM_opcode, MEM_WB_opcode;

reg [1:0] Rt, Rd;                                   //for ID/EX latch, register

reg [5:0] ID_EX_funct, EX_MEM_funct, MEM_WB_funct;

reg [15:0] ID_EX_rs_data, EX_MEM_rs_data, MEM_WB_rs_data;
reg [15:0] ID_EX_rt_data, EX_MEM_rt_data;
reg[11:0] ID_EX_target_address;

reg [15:0] signextend_im, shiftleft_im;             //for ID/EX latch

reg branch_condition;                               //for EX/MEM latch

reg [15:0] jump_address, branch_address;            //for EX/MEM latch

reg [1:0] EX_MEM_write_register, MEM_WB_write_register; //RF_write_register
reg [15:0] EX_MEM_ALUresult, MEM_WB_ALUresult;

reg [15:0] MEM_read_data;                           // for MEM/WB latch

reg [15:0] IF_ID_nextPC, ID_EX_nextPC, EX_MEM_nextPC, MEM_WB_nextPC;

reg [15:0] curr_instruction;                             //for IF/ID latach


//wire flush;

wire [1:0] rd;
wire [7:0] immediate;
wire [11:0] target_address;

//decode
assign opcode=curr_instruction[15:12];
assign rs=curr_instruction[11:10];
assign rt=curr_instruction[9:8];
assign rd=curr_instruction[7:6];
assign funct=curr_instruction[5:0];
assign immediate=curr_instruction[7:0];
assign target_address=curr_instruction[11:0];


wire [15:0] ALUinputA, ALUinputB;    //wire from ALUsrc mux to ALU
wire [15:0] RF_write_data;           //wire from MEMtoReg mux to RF write data
wire [15:0] PCinput;                 //wire for PC counter input
wire [15:0] PCaddoutput;             //wire for PC+1 output

//WWD
always@(posedge clk)begin
    if(output_signal)begin
        output_port=MEM_WB_rs_data;
    end
end

//mux
assign RegDst_output=(RegDst==2'b00)?Rt:
                     (RegDst==2'b01)?Rd:
                                     2'b10;

assign ALUinputA = ALUsrcA ? shiftleft_im : ID_EX_rs_data;
assign ALUinputB = ALUsrcB ? signextend_im : ID_EX_rt_data;

assign RF_write_data= (MEMtoReg==2'b00)?MEM_WB_ALUresult:
                      (MEMtoReg==2'b10)?MEM_read_data:
                                        MEM_WB_nextPC;
assign PCinput=(PCsrc==2'b00)?PCaddoutput:
               (PCsrc==2'b01)?branch_address:
               (PCsrc==2'b10)?jump_address:
                              EX_MEM_rs_data;

wire [15:0] read_data1, read_data2, ALU_result, branch_add_result;  //RF_output1,output2   ALU_output   Branch_jump_output
wire branchcond;        //ALU branch output

//reset
always@(*)begin
    if(!reset_n)begin
        curr_instruction=`bubble_inst;
        ID_EX_opcode=`OPCODE_Bubble;
        EX_MEM_opcode=`OPCODE_Bubble;
        MEM_WB_opcode=`OPCODE_Bubble;
    end
end

//update buffer
always@(posedge clk) begin
    if(reset_n)begin
        if((!data_stall)&(!jump_stall))begin
            //IF/ID buffer
            curr_instruction<=Imemdata;
        end
        if(!data_stall)begin
            //IF/ID buffer
            IF_ID_nextPC<=PCaddoutput;
            //ID/EX buffer
            ID_EX_funct<=funct;
            ID_EX_opcode<=opcode;
            ID_EX_nextPC<=IF_ID_nextPC;
            ID_EX_rs_data<=read_data1;
            ID_EX_rt_data<=read_data2;
            Rt<=rt;
            Rd<=rd;
            signextend_im<={{8{immediate[7]}}, immediate[7:0]};
            shiftleft_im<=immediate<<8;
            ID_EX_target_address<=target_address;
        end
        //EX/MEM buffer
        EX_MEM_funct<=ID_EX_funct;
        EX_MEM_opcode<=ID_EX_opcode;
        EX_MEM_ALUresult<=ALU_result;
        EX_MEM_nextPC<=ID_EX_nextPC;
        EX_MEM_rs_data<=ID_EX_rs_data;
        EX_MEM_rt_data<=ID_EX_rt_data;
        EX_MEM_write_register<=RegDst_output;
        branch_condition<=branchcond;
        branch_address<=branch_add_result;
        jump_address<={ID_EX_nextPC[15:12], ID_EX_target_address};
        //MEM/WB buffer
        MEM_WB_funct<=EX_MEM_funct;
        MEM_WB_ALUresult<=EX_MEM_ALUresult;         //memory address, write data
        MEM_WB_opcode<=EX_MEM_opcode;
        MEM_WB_write_register<=EX_MEM_write_register;
        MEM_WB_nextPC<=EX_MEM_nextPC;
        MEM_read_data<=Dmemdata;
        MEM_WB_rs_data<=EX_MEM_rs_data;
        
        //flush
        if(flush)begin
            curr_instruction<=`bubble_inst;
            ID_EX_opcode<=`OPCODE_Bubble;
            EX_MEM_opcode<=`OPCODE_Bubble;
        end
        //avoid data hazard
        else if(data_stall)begin
            ID_EX_opcode<=`OPCODE_Bubble;
        end
        //avoid control hazard
        else if(jump_stall)begin
            curr_instruction<=`bubble_inst;
        end
    end
end

//implement module
RF rf00(RegWrite, clk, reset_n, rs, rt, MEM_WB_write_register, RF_write_data, read_data1, read_data2);
ALU alu00(.A(ALUinputA), .B(ALUinputB), .Cin(0), .OP(ALUop), .ALU_result(ALU_result), .branch_condition(branchcond), .Cout());

assign branch_add_result=ID_EX_nextPC+signextend_im;
assign PCaddoutput=current_PC+1;

wire[15:0] next_PC;
//implement module
PCcounter pc00(next_PC, clk, PCwrite, reset_n, current_PC);
BTB btb00(clk, reset_n, data_stall, jump_stall, current_PC, PCinput, PCsrc, EX_MEM_nextPC, EX_MEM_opcode, EX_MEM_funct, branch_address, next_PC, IF_ID_no_btb, ID_EX_no_btb, EX_MEM_no_btb, flush);

endmodule