module BTB(
    input clk,
    input reset_n,
    input[15:0] PC,
    input[15:0] jumpPC,
    input[1:0] PCsrc,
    output[15:0] next_PC,
    output[15:0] no_btb
);
    reg pre_no_btb, IF_no_btb, no_btb;
    reg[15:0] BTB_history [255:0];
    always@(*)begin
        if(!reset_n)begin
            pre_no_btb=0;
            IF_no_btb=0;
            no_btb=0;
            for(int i=0;i<256;i++)
                BTB_history[i]=16'h0000;
        end
    end

    always@(*)begin
        if(reset_n)begin
            if(BTB_history[PC]!=16'h0000) begin
                next_PC=BTB_history[PC];
                pre_no_btb=0;
            end
            else if(PCsrc==2'b10||PCsrc==2'b01)begin
                BTB_history[PC-1]=jumpPC;
                next_PC=jumpPC;
                pre_no_btb=0;
            end
            else begin
                next_PC=PC+1;
                pre_no_btb=1;
            end
        end
    end
    always@(posedge clk)begin
        if((!data_stall)&(!jump_stall)&(!flush))begin
            IF_no_btb<=pre_no_btb;
            no_btb<=IF_no_btb;
        end
        else begin
            IF_no_btb<=0;
            no_btb<=0;
        end
    end

endmodule