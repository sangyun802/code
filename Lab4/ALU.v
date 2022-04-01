module ALU(
    input [3:0] aluop,
    input [5:0] funct,
    input [15:0] read_data1,
    input [15:0] read_data2,
    output reg [15:0] output_port,
    output reg [15:0] calculate_data
);
    always@(*) begin
        case(aluop):
            `OPCODE_RTYPE:begin
                case(funct)
                    `FUNC_ADD:calculate_data=read_data1+read_data2;
                    `FUNC_WWD:begin 
                        calculate_data=read_data2;
                        output_port=read_data1;
                    end
                endcase
            end
            `OPCODE_ADI:calculate_data=read_data1+read_data2;
            `OPCODE_LHI:calculate_data=read_data2<<8;
        endcase
    end

endmodule