`define FUNC_ADD 6'd0
`define FUNC_SUB 6'd1
`define FUNC_AND 6'd2
`define FUNC_ORR 6'd3
`define FUNC_NOT 6'd4
`define FUNC_TCP 6'd5
`define FUNC_SHL 6'd6
`define FUNC_SHR 6'd7

`define FUNC_JPR 6'd25
`define FUNC_JRL 6'd26
`define FUNC_WWD 6'd28
`define FUNC_HLT 6'd29

`define OPCODE_ADI 4'd4
`define OPCODE_ORI 4'd5
`define OPCODE_LHI 4'd6
`define OPCODE_LWD 4'd7
`define OPCODE_SWD 4'd8
`define OPCODE_BNE 4'd0
`define OPCODE_BEQ 4'd1
`define OPCODE_BGZ 4'd2
`define OPCODE_BLZ 4'd3
`define OPCODE_JMP 4'd9
`define OPCODE_JAL 4'd10

`define OPCODE_Rtype 4'd15

//For bubble
`define OPCODE_Bubble 4'd11
`define bubble_inst 16'hb000

//For aluop
`define OP_ADD  4'd0
`define OP_SUB  4'd1
`define OP_ID   4'd2
`define OP_BNE  4'd3
`define OP_BEQ  4'd4
`define OP_BGZ  4'd5
`define OP_BLZ  4'd6
`define OP_TCP  4'd7
`define OP_NOT  4'd8
`define OP_AND  4'd9
`define OP_OR   4'd10
`define OP_ARS  4'd11
`define OP_LLS  4'd12