`define WORD_SIZE 16
/*************************************************
* DMA module (DMA.v)
* input: clock (CLK), bus request (BR) signal, 
*        data from the device (edata), and DMA command (cmd)
* output: bus grant (BG) signal 
*         READ signal
*         memory address (addr) to be written by the device, 
*         offset device offset (0 - 2)
*         data that will be written to the memory
*         interrupt to notify DMA is end
* You should NOT change the name of the I/O ports and the module name
* You can (or may have to) change the type and length of I/O ports 
* (e.g., wire -> reg) if you want 
* Do not add more ports! 
*************************************************/

module DMA (
    input CLK, BG, reset_n,
    input [4 * `WORD_SIZE - 1 : 0] edata,
    input cmd,
    output reg BR, 
    output WRITE,
    output [`WORD_SIZE - 1 : 0] addr, 
    output [4 * `WORD_SIZE - 1 : 0] data,
    output reg [1:0] offset,
    output reg interrupt);

    /* Implement your own logic */

    reg [1:0] counter;
    reg write;
    always@(posedge CLK)begin
        if(reset_n)begin
            if(BG&BR) begin
                write<=1;
                counter<=counter+1;
                if(counter==2'b00)
                    offset<=offset+1;
            end
            else begin
                write<=0;
                counter<=2'b00;
                offset<=2'b11;
            end

            if(cmd&(offset!=2'b10))begin
                BR<=1;
            end
            else if(((counter==2'b11)&(offset==2'b10))|!cmd)begin
                BR<=0;
                write<=0;
                counter<=2'b00;
            end

            if(interrupt)begin
                interrupt<=0;
            end
        end
    end
    always@(negedge BG)begin
        interrupt<=1;
    end

    assign data=BG?edata:64'bz;
    assign WRITE=BG?write:1'bz;
    assign addr=(BG&(offset!=2'b11))?(16'h1f4+4*offset):16'bz;

endmodule


