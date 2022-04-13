module Datapath(
    input[15:0] instruction,
    input[15:0] Memreaddata,
    input clk,
    input reset_n,
    input PCWriteCond,
    input PCWrite,
    input IorD,
    input MemRead,
    input MemWrite,
    input MemtoReg,
    input IRWrite,
    input [1:0]RegDst,
    input Regwrite,
    input [1:0]ALUsrcA,
    input [1:0]ALUsrcB,
    input [3:0]ALUOP,
    input [1:0] PCSource,
    input Memout,
    output [15:0]output_port,
    output [3:0] opcode,
    output [5:0] funct,
    output[15:0] address,
    output[15:0] Memwritedata
);
    reg[15:0] ALUout;
    wire [3:0] opcode;
    wire [1:0] rs, rt, rd;
    wire [11:0] target_address;
    wire [7:0] immediate;
    wire [5:0] funct;
    Instruction_decoder Id00(instruction, clk, reset_n, IRWrite, opcode, rs, rt, rd, target_address, immediate, funct);
    
    wire [15:0] jump_address={PC[15:11], target_address};

    wire[15:0] ALU_result, PC;
    reg[15:0] next_PC, address;
    reg[15:0] ALU_input1, ALU_input2;
    wire branch_condition;
    wire PCupdate=(branch_condition&PCWriteCond)|PCWrite;

    PCcounter Pc00(next_PC, clk, PCupdate, reset_n, PC);

    reg [1:0] write_register;

    always@(*)begin
        case(RegDst)
            2'b00:write_register=rt;
            2'b01:write_register=rd;
            2'b10:write_register=2'b10;
        endcase
    end


    reg [15:0] write_data;
    always@(*)begin
        if(MemtoReg)begin
            write_data=Memreaddata;
        end
        else begin
            write_data=ALUout;
        end
    end
    wire[15:0] read_data1, read_data2;   //rs, rt
    
    assign Memwritedata=read_data2;

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

    reg[15:0] output_port;
    
    always@(*) begin
        if(Memout)begin
            output_port=read_data1;
        end
    end

    wire[15:0] signextend_im, shifted_im;
    assign signextend_im={{8{immediate[7]}}, immediate[7:0]};
    assign shifted_im=immediate<<8;

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

    always@(*)begin
        case(PCSource)
            2'b00:next_PC=ALU_result;
            2'b01:next_PC=jump_address;
            2'b10:next_PC=PC+signextend_im;
            2'b11:next_PC=read_data1;
        endcase
    end

    always@(*)begin
        if(IorD) begin
            address=ALUout;
        end
        else begin
            address=PC;
        end
    end


endmodule