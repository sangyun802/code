`timescale 100ps / 100ps

//LSB는 state의 output, 나머지 bit는 해당 state 표시
`define start_0     3'b000          //처음 0을 인식
`define reset_1     3'b010          //reset 혹은 연속한 1 인식(ex. 011)
`define detect_0    3'b101          //010 인식(output 1)
`define part_1      3'b110          //0 다음에 오는 1 인식

module detector(
    input clk,                      //clock
    input reset_n,                  //reset signal
    input in,                       //input
    output out                      //010 detect시 1출력
);
    reg [2:0] curr_state, next_state;       //3 bit current state, next state
    reg out;
    always@(*) begin
        
        //reset시 current state와 next state 모두 reset_1로 reset하기(asynchronous)
        if(reset_n==0)begin
            curr_state=`reset_1;
            next_state=`reset_1;
        end
        
        //current state에서 input에 따라 next_state 정하기(asynchronous)
        case(curr_state)
            
            `start_0: next_state=(in==1)?`part_1:`start_0;

            `reset_1: next_state=(in==1)?`reset_1:`start_0;

            `part_1: next_state=(in==1)?`reset_1:`detect_0;
            
            `detect_0: next_state=(in==1)?`part_1:`start_0;
            
        endcase

    end

    //clock의 positive edge에 맞춰서 next state를 current state로 바꾸기
    always@(posedge clk) begin
    curr_state<=next_state;
    end

    //output은 curr_state의 LSB
    always@(*)begin
    out=curr_state[0];
end

endmodule