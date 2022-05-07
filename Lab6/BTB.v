module BTB(
    input clk,
    input reset_n,
    input data_stall,
    input jump_stall,
    input[15:0] PC,
    input[15:0] PCinput,
    input[1:0] PCsrc,
    input[15:0] EX_MEM_nextPC,
    input[3:0] EX_MEM_opcode,
    input[5:0] EX_MEM_funct,
    input[15:0] branch_address,
    output reg [15:0] next_PC,
    output IF_ID_no_btb,
    output ID_EX_no_btb,
    output EX_MEM_no_btb,
    output flush
);
    integer count;  //for memory reset
    reg IF_no_btb, IF_ID_no_btb, ID_EX_no_btb, EX_MEM_no_btb;   //no_btb become 0 when use branch prediction
    reg[15:0] BTB_history [255:0];                              //BTB memory
    reg[15:0] IF_PC_jump, IF_ID_PC_jump, ID_EX_PC_jump, EX_MEM_PC_jump;     //PC which instruction is jump_instruction
    reg[15:0] IF_predict_address, IF_ID_predict_address, ID_EX_predict_address, EX_MEM_predict_address; //to check predict_address and real address

    //reset
    always@(*)begin
        if(!reset_n)begin
            for(count=0;count<256;count=count+1)
                BTB_history[count]=16'h0000;
        end
    end

    //checking if it is jump_instruction in MEM stage
    wire EX_MEM_jump_instruction=(EX_MEM_opcode==`OPCODE_JMP)|(EX_MEM_opcode==`OPCODE_JAL)
                                |(EX_MEM_opcode==`OPCODE_BEQ)|(EX_MEM_opcode==`OPCODE_BGZ)|(EX_MEM_opcode==`OPCODE_BLZ)|(EX_MEM_opcode==`OPCODE_BNE)
                                |((EX_MEM_opcode==`OPCODE_Rtype)&((EX_MEM_funct==`FUNC_JPR)|(EX_MEM_funct==`FUNC_JRL)));

    //flush
    assign flush=EX_MEM_jump_instruction&(EX_MEM_predict_address!=PCinput)&(!EX_MEM_no_btb);

    always@(*)begin
        if(reset_n)begin
            //flush
            if(flush)begin
                //predict as taken but misprediction
                if(PCsrc==2'b01|PCsrc==2'b10|PCsrc==2'b11) begin
                    next_PC=PCinput;
                    BTB_history[EX_MEM_PC_jump]=PCinput;    //modify address in BTB
                end
                //predict as taken but not taken actually
                else begin
                    next_PC=EX_MEM_nextPC;
                end
            end
            //jump_stall
            else if(jump_stall)begin
                IF_no_btb=0;
                if(EX_MEM_no_btb)begin
                    //if new branch was taken
                    if(PCsrc==2'b10|PCsrc==2'b01|PCsrc==2'b11)begin
                        BTB_history[PC-1]=PCinput;      //new address update in BTB
                        next_PC=PCinput;
                    end
                    else begin
                        //if new branch was not taken
                        if(EX_MEM_opcode==`OPCODE_BEQ|EX_MEM_opcode==`OPCODE_BNE|EX_MEM_opcode==`OPCODE_BGZ|EX_MEM_opcode==`OPCODE_BLZ)begin
                            BTB_history[PC-1]=branch_address;   //new address update in BTB
                        end
                        next_PC=PC;
                    end                
                end
            end
            //if there is jumping address in BTB
            else if(BTB_history[PC]!=16'h0000) begin
                next_PC=BTB_history[PC];
                IF_predict_address=BTB_history[PC];
                IF_PC_jump=PC;
                IF_no_btb=0;
            end
            //no address in BTB
            else begin
                next_PC=PC+1;
                IF_no_btb=1;
            end
        end
    end
    always@(posedge clk)begin
        if(reset_n) begin
            if(!data_stall)begin
                IF_ID_no_btb<=IF_no_btb;
                ID_EX_no_btb<=IF_ID_no_btb;
                IF_ID_predict_address<=IF_predict_address;
                ID_EX_predict_address<=IF_ID_predict_address;
                IF_ID_PC_jump<=IF_PC_jump;
                ID_EX_PC_jump<=IF_ID_PC_jump;
            end
            EX_MEM_no_btb<=ID_EX_no_btb;
            EX_MEM_predict_address<=ID_EX_predict_address;
            EX_MEM_PC_jump<=ID_EX_PC_jump;

            if(flush)begin
                IF_no_btb<=0;
                IF_ID_no_btb<=0;
                ID_EX_no_btb<=0;
                EX_MEM_no_btb<=0;
                IF_predict_address<=16'h0000;
                IF_ID_predict_address<=16'h0000;
                ID_EX_predict_address<=16'h0000;
                EX_MEM_predict_address<=16'h0000;
                IF_PC_jump<=16'h0000;
                IF_ID_PC_jump<=16'h0000;
                ID_EX_PC_jump<=16'h0000;
                EX_MEM_PC_jump<=16'h0000;
            end
            if(data_stall)begin
                ID_EX_no_btb<=0;
                ID_EX_predict_address<=16'h0000;
                ID_EX_PC_jump<=16'h0000;
            end
    end
end

endmodule