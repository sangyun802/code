module PCcounter(
    input jump,
    input [11:0] target_address,
    input clk,
    input reset_n,
    output [15:0]PC
);
    reg[15:0] PC;

    always@(posedge clk) begin
        //reset
        if(!reset_n) begin
            PC<=-1;
        end
        //PC change
        else begin
            PC<=(jump)?{PC[15:12], target_address}:(PC+1);
        end
    end

endmodule