
`define WORD_SIZE 16                    //register size
`define NUM_REG 4                       //number of register


module RF(
    input write,                        //write signal
    input clk,                          //clock
    input reset_n,                      //if reset_n=0, reset RF
    input[1:0] read_register1,                   //address1 (read_data1's address)
    input[1:0] read_register2,                   //address2 (read_data2's address)
    input[1:0] write_register,                   //address3 (write_data's address)
    input[`WORD_SIZE-1:0] write_data,        
    output[`WORD_SIZE-1:0] read_data1,
    output[`WORD_SIZE-1:0] read_data2
);
    reg[`WORD_SIZE-1:0] registers [`NUM_REG-1:0];

    //read data from rf(asynchronous)
    assign read_data1=registers[read_register1];
    assign read_data2=registers[read_register2];
    
    
    
    always@(posedge clk) begin
        //reset
        if(reset_n==0)begin
            registers[0]<=16'h0000;
            registers[1]<=16'h0000;
            registers[2]<=16'h0000;
            registers[3]<=16'h0000;
        end
        //write data
        if( write & reset_n )begin
            registers[write_register]<=write_data;
        end
    end

endmodule