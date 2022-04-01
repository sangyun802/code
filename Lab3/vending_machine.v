// Title         : vending_machine.v
// Author      : Hunjun Lee (hunjunlee7515@snu.ac.kr), Suheon Bae (suheon.bae@snu.ac.kr)

`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered

	o_available_item,			// Sign of the item availability
	o_output_item,			   // Sign of the item withdrawal
	o_return_coin,			   // Sign of the coin return
	o_current_total
);

	// Ports Declaration
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;

	output [`kNumItems-1:0] o_available_item;
	output [`kNumItems-1:0] o_output_item;
	output [`kReturnCoins-1:0] o_return_coin;
	output [`kTotalBits-1:0] o_current_total;

	// Net constant values (prefix kk & CamelCase)
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;

	// Internal states. You may add your own reg variables.
	reg [`kTotalBits-1:0] current_total;		//current state에서 vending machine이 가지고 있는 잔액
	reg [`kTotalBits-1:0] next_total;			//next state에서 vending machine이 가지고 있는 잔액
	reg [`kTotalBits-1:0] curr_return_total;	//current state에서 잔돈으로 반환할 돈의 액수
	reg [`kTotalBits-1:0] next_return_total;	//next state에서 잔돈으로 반환할 돈의 액수
	reg[`kNumItems-1:0] curr_output_item;		//current state에서 구매한 상품
	reg[`kNumItems-1:0] next_output_item;		//next state에서 구매한 상품
	
	//output
	reg[`kNumItems-1:0] o_available_item;		//사용자가 구매할 수 있는 상품
	reg [`kNumItems-1:0] o_output_item;			//사용자가 구매한 상품
	reg [`kReturnCoins-1:0] o_return_coin;		//사용자에게 반환할 돈
	reg [`kTotalBits-1:0] o_current_total;		//자판기에 남아있는 돈
	
	reg [`kTotalBits-1:0] insert_total;			//투입한 돈의 액수
	reg [`kTotalBits-1:0] output_total;			//상품을 구매할 때 구매할 상품의 가격


	//not used
	//reg [`kItemBits-1:0] num_items [`kNumItems-1:0]; //use if needed
	//reg [`kCoinBits-1:0] num_coins [`kNumCoins-1:0]; //use if needed

	// Combinational circuit for the next states
	always @(*) begin
		//투입한 돈의 액수 구하기
		insert_total=i_input_coin[0]*kkCoinValue[0]+i_input_coin[1]*kkCoinValue[1]+i_input_coin[2]*kkCoinValue[2];
		
		next_output_item=i_select_item&o_available_item; // 선택한 상품이 구매할 수 있는 상품인지 판단
		
		//구매할 상품의 가격
		output_total=next_output_item[0]*kkItemPrice[0]+next_output_item[1]*kkItemPrice[1]+next_output_item[2]*kkItemPrice[2]+next_output_item[3]*kkItemPrice[3];

		//next state에서 vending machine에 남은 돈 계산
		next_total=current_total+insert_total-output_total;
		
		//잔돈 반환시
		if(i_trigger_return!=0)begin
			next_total=0;
			next_return_total=current_total; //현재 남아있는 돈을 전부 next state에서 반환
		end
		//돈 투입 혹은 상품 구매시
		else begin
			next_return_total=0;
		end
	end
	// Combinational circuit for the output
	always @(*) begin
		o_current_total=current_total;
		o_output_item=curr_output_item;

		//자판기에 남아있는 돈 액수에 따라 구매 가능한 상품 표시
		if(current_total>=kkItemPrice[3])begin
			o_available_item=4'b1111;
		end
		else if(current_total>=kkItemPrice[2])begin
			o_available_item=4'b0111;
		end
		else if(current_total>=kkItemPrice[1])begin
			o_available_item=4'b0011;
		end
		else if(current_total>=kkItemPrice[0])begin
			o_available_item=4'b0001;
		end
		else begin
			o_available_item=4'b0000;
		end

		//잔돈 반환
		o_return_coin=curr_return_total/1000+(curr_return_total%1000)/500+(curr_return_total%500)/100;

	end


	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
			current_total<=0;
			next_total<=0;
			curr_return_total<=0;
			next_return_total<=0;
			curr_output_item<=0;
			next_output_item<=0;
		end
		else begin
			// TODO: update all states.
			current_total<=next_total;
			curr_output_item<=next_output_item;
			curr_return_total<=next_return_total;
		end
	end

endmodule
