module Datapath(
    input[15:0] instruction,
    input[15:0] Memreaddata,    //input from memory
    input clk,
    input reset_n,
    //output from control unit
    input PCWriteCond,
    input PCWrite,
    input IorD,
    input MemRead,
    input MemWrite,
    input [1:0] MemtoReg,
    input IRWrite,
    input [1:0]RegDst,
    input Regwrite,
    input [1:0]ALUsrcA,
    input [1:0]ALUsrcB,
    input [3:0]ALUOP,
    input [1:0] PCSource,
    input Memout,
    //WWD
    output [15:0]output_port,
    //input to control unit
    output [3:0] opcode,
    output [5:0] funct,
    output[15:0] address,       //input address to memory
    output[15:0] Memwritedata   //output to memory
);
    reg[15:0] output_port;

    always@(*) begin
        if(Memout)begin
            output_port=read_data1;
        end
    end
    
    reg[15:0] ALUout;       //ALU output register(store ALU_result)
    wire[15:0] ALU_result;  //ALU output
    
    wire [3:0] opcode;
    wire [1:0] rs, rt, rd;
    wire [11:0] target_address;
    wire [7:0] immediate;
    wire [5:0] funct;
    Instruction_decoder Id00(instruction, clk, reset_n, IRWrite, opcode, rs, rt, rd, target_address, immediate, funct); //instruction decoding
    

    wire[15:0] PC;
    reg[15:0] next_PC, address;
    reg[15:0] ALU_input1, ALU_input2;
    wire branch_condition;                                      //bne, beq, blz, bgz
    wire PCupdate=(branch_condition&PCWriteCond)|PCWrite;       //determine PC update

    PCcounter Pc00(next_PC, clk, PCupdate, reset_n, PC);

    reg [1:0] write_register;
    //determine write_register address
    always@(*)begin
        case(RegDst)
            2'b00:write_register=rt;    //Itype
            2'b01:write_register=rd;    //Rtype
            2'b10:write_register=2'b10; //JAL,JRL
        endcase
    end


    reg [15:0] write_data;
    //determine write_data in registerfile
    always@(*)begin
        case(MemtoReg)
            2'b00: write_data=ALUout;
            2'b01: write_data=Memreaddata;  //LWD
            2'b10: write_data=PC;           //JAL,JRL
         endcase
    end

    wire[15:0] read_data1, read_data2;   //rs, rt
    
    assign Memwritedata=read_data2;     //input data to Memory (for SWD)

    RF rf00(
        .write(Regwrite), 
        .clk(clk), 
        .reset_n(reset_n), 
        .read_register1(rs), 
        .read_register2(rt), 
        .write_register(write_register), 
        .write_data(write_data), 
        .read_data1(read_data1), 
        .read_data2(read_data2)
    );


    wire[15:0] signextend_im, shifted_im;
    assign signextend_im={{8{immediate[7]}}, immediate[7:0]};   //Itype
    assign shifted_im=immediate<<8;                             //LHI


    always@(*)begin
        case(ALUsrcA)
            2'b00:ALU_input1=PC;
            2'b01:ALU_input1=read_data1;
            2'b10:ALU_input1=shifted_im;
        endcase
        case(ALUsrcB)
            2'b00:ALU_input2=read_data2;
            2'b01:ALU_input2=16'd1;
            2'b10:ALU_input2=signextend_im;
        endcase
        ALUout=ALU_result;
    end

    ALU alu00(
        .A(ALU_input1),
        .B(ALU_input2),
        .Cin(0),
        .OP(ALUOP),
        .ALU_result(ALU_result),
        .branch_condition(branch_condition),
        .Cout()
    );

    wire [15:0] jump_address={PC[15:11], target_address};   //JMP, JAL

    always@(*)begin
        case(PCSource)
            2'b00:next_PC=ALU_result;       //for PC+1
            2'b01:next_PC=jump_address;     //JMP, JAL
            2'b10:next_PC=ALUout;           //bne, beq, bgz, blz
            2'b11:next_PC=read_data1;       //JPR,JRL
        endcase
    end

    always@(*)begin
        if(IorD) begin
            address=ALUout;         //LWD, SWD
        end
        else begin
            address=PC;             //instruction fetch
        end
    end


endmodule