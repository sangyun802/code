`define ST_taken 2'b11  //Strongly taken
`define WE_taken 2'b10  //weakly taken
`define WE_n_taken 2'b01    //strongly not taken
`define ST_n_taken 2'b00    //weakly not taken

module BTB(
    input clk,
    input reset_n,
    input data_stall,
    input jump_stall,
    //input flush,
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
    integer count;      //for memory reset
    reg IF_no_btb, IF_ID_no_btb, ID_EX_no_btb, EX_MEM_no_btb;   //no_btb become 0 when use branch prediction
    reg[15:0] BTB_history [255:0];                              //BTB memory
    reg[15:0] IF_PC_jump, IF_ID_PC_jump, ID_EX_PC_jump, EX_MEM_PC_jump; //PC which instruction is jump_instruction
    reg[15:0] IF_predict_address, IF_ID_predict_address, ID_EX_predict_address, EX_MEM_predict_address; //to check predict_address and real address
    reg[1:0] BHT;           //for 2-bit branch prediction
    

    //reset
    always@(*)begin
        if(!reset_n)begin
            BHT=`ST_n_taken;
            for(count=0;count<256;count=count+1)
                BTB_history[count]=16'h0000;
        end
    end

    wire EX_MEM_jump_instruction=(EX_MEM_opcode==`OPCODE_JMP)|(EX_MEM_opcode==`OPCODE_JAL)
                                |(EX_MEM_opcode==`OPCODE_BEQ)|(EX_MEM_opcode==`OPCODE_BGZ)|(EX_MEM_opcode==`OPCODE_BLZ)|(EX_MEM_opcode==`OPCODE_BNE)
                                |((EX_MEM_opcode==`OPCODE_Rtype)&((EX_MEM_funct==`FUNC_JPR)|(EX_MEM_funct==`FUNC_JRL)));

    //flush
    assign flush=EX_MEM_jump_instruction&(EX_MEM_predict_address!=PCinput)&!EX_MEM_no_btb;

    always@(*)begin
        if(reset_n)begin
            if(flush)begin
                //predict as taken but misprediction
                if(PCsrc==2'b01|PCsrc==2'b10|PCsrc==2'b11) begin
                    next_PC=PCinput;
                    BTB_history[EX_MEM_PC_jump]=PCinput;
                end
                //predict as taken but not taken actually
                else begin
                    next_PC=EX_MEM_nextPC;
                end
            end
            else if(jump_stall)begin
                IF_no_btb=0;
                if(EX_MEM_no_btb)begin
                    //if new branch was taken
                    if(PCsrc==2'b10|PCsrc==2'b01|PCsrc==2'b11)begin
                        BTB_history[PC-1]=PCinput;
                        next_PC=PCinput;
                    end
                    else begin
                        //if new branch was not taken
                        if(EX_MEM_opcode==`OPCODE_BEQ|EX_MEM_opcode==`OPCODE_BNE|EX_MEM_opcode==`OPCODE_BGZ|EX_MEM_opcode==`OPCODE_BLZ)begin
                            BTB_history[PC-1]=branch_address;
                        end
                        next_PC=PC;
                    end                
                end
            end
            //if there is jumping address in BTB
            else if(BTB_history[PC]!=16'h0000) begin
                IF_no_btb=0;
                //if taken
                if(BHT==`ST_taken|BHT==`WE_taken) begin
                    next_PC=BTB_history[PC];
                    IF_predict_address=BTB_history[PC];
                    IF_PC_jump=PC;
                end
                //if not taken
                else if(BHT==`ST_n_taken|BHT==`WE_n_taken)begin
                    next_PC=PC+1;
                    IF_predict_address=PC+1;
                    IF_PC_jump=PC;
                end
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
            
            // for BHT
            //saturation
            if(!EX_MEM_no_btb)begin
                //if taken
                if(PCsrc!=2'b00)begin
                    case(BHT)
                        `ST_taken:BHT<=`ST_taken;
                        `WE_taken:BHT<=`ST_taken;
                        `WE_n_taken:BHT<=`WE_taken;
                        `ST_n_taken:BHT<=`WE_n_taken;
                    endcase
                end
                //if not taken
                else if(EX_MEM_jump_instruction)begin
                    case(BHT)
                        `WE_taken:BHT<=`WE_n_taken;
                        `WE_n_taken:BHT<=`ST_n_taken;
                        `ST_taken:BHT<=`WE_taken;
                    endcase
                end
            end
            //hysteresis
            /*if(!EX_MEM_no_btb)begin
                if(PCsrc!=2'b00)begin
                    if(BHT==`ST_n_taken)begin
                        BHT<=`WE_n_taken;
                    end
                    else begin
                        BHT<=`ST_taken;
                    end
                end
                else if(EX_MEM_jump_instruction)begin
                    if(BHT==`ST_taken)begin
                        BHT<=`WE_taken;
                    end
                    else begin
                        BHT<=`ST_n_taken;
                    end
                end
            end*/
        end
    end

endmodule