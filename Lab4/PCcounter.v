module PCcounter(
    input[15:0] current_address,
    input jump,
    input [11:0] target_address,
    output [15:0] next_address
);
    wire[15:0] immediate_address;
    assign immediate_address=current_address+1;
    assign next_address=(jump)?{immediate_address[15:12], target_address}:immediate_address;

endmodule