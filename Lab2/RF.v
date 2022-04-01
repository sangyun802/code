`timescale 100ps / 100ps

`define WORD_SIZE 16                    //register 크기
`define NUM_REG 4                       //register 개수


module RF(
    input write,                        //write signal
    input clk,                          //clock
    input reset_n,                      //if reset_n=0, reset RF
    input[1:0] addr1,                   //address1 (data1의 주소를 가리키는 address)
    input[1:0] addr2,                   //address2 (data2의 주소를 가리키는 address)
    input[1:0] addr3,                   //address3 (write signal 받을 시 data를 적을 address)
    input[`WORD_SIZE-1:0] data3,        //write signal 받을시 입력할 데이터
    output[`WORD_SIZE-1:0] data1,       //주소로 address1을 가지는 데이터
    output[`WORD_SIZE-1:0] data2        //주소로 address1을 가지는 데이터
);
    reg[`WORD_SIZE-1:0] registers [`NUM_REG-1:0];   //16bit 크기의 register 4개 선언

    //regeister의 address에 저장된 data 읽어오기(asynchronous)
    assign data1=registers[addr1];
    assign data2=registers[addr2];
    
    //reset signal 들어오면 reset 실행(asynchronous)
    always@(*)begin
        if(reset_n==0)begin
            registers[0]<=16'h0000;
            registers[1]<=16'h0000;
            registers[2]<=16'h0000;
            registers[3]<=16'h0000;
        end
    end
    
    //write signal 들어오면 input으로 받은 address에 data write
    always@(posedge clk) begin
        if(write==1)begin
            registers[addr3]<=data3;
        end
    end

endmodule