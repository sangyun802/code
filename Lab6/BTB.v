module BTB(
    input clk,
    input reset_n,
    input data_stall,
    input jump_stall,
    input flush,
    input[15:0] PC,
    input[15:0] jumpPC,
    input[1:0] PCsrc,
    input[15:0] EX_MEM_nextPC,
    output reg [15:0] next_PC,
    output IF_ID_no_btb,
    output ID_EX_no_btb,
    output EX_MEM_no_btb
);
    integer count;
    reg pre_no_btb, IF_no_btb, IF_ID_no_btb, ID_EX_no_btb, EX_MEM_no_btb;
    reg[15:0] BTB_history [255:0];
    always@(*)begin
        if(!reset_n)begin
            for(count=0;count<256;count=count+1)
                BTB_history[count]=16'h0000;
        end
    end

    always@(*)begin
        if(reset_n)begin
            if(jump_stall)begin
                IF_no_btb=0;
                if(EX_MEM_no_btb)begin
                    if(PCsrc==2'b10|PCsrc==2'b01)begin
                        BTB_history[PC-1]=jumpPC;
                        next_PC=jumpPC;
                    end
                    else if(PCsrc==2'b11)begin
                        next_PC=jumpPC;
                    end
                    else begin
                        next_PC=PC;
                    end                
                end
            end
            else if(flush)begin
                next_PC=EX_MEM_nextPC;
            end
            else if(BTB_history[PC]!=16'h0000) begin
                next_PC=BTB_history[PC];
                IF_no_btb=0;
            end
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
            end
            EX_MEM_no_btb<=ID_EX_no_btb;

            if(flush)begin
                IF_no_btb<=0;
                IF_ID_no_btb<=0;
                ID_EX_no_btb<=0;
            end
            if(data_stall)begin
                ID_EX_no_btb<=0;
            end
    end
end

endmodule