module PCcounter(
    input [15:0] next_PC,
    input clk,
    input PCwrite,
    input reset_n,
    output [15:0] PC
);
    reg [15:0] PC;

    always@(*)begin
        //reset
        if(!reset_n) begin
            PC<=16'h0000;    
        end
    end
    always@(posedge clk) begin
        //PC update
        if(reset_n)begin
            if(PCwrite) begin
                PC<=next_PC;
            end
        end
    end

endmodule