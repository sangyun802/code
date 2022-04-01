///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 
// Description: 

// DEFINITIONS
`define WORD_SIZE 16    // data and address word size

// INCLUDE files
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions

// MODULE DECLARATION
module cpu (
  output readM,                       // read from memory
  output [`WORD_SIZE-1:0] address,    // current address for data
  inout [`WORD_SIZE-1:0] data,        // data being input or output
  input inputReady,                   // indicates that data is ready from the input port
  input reset_n,                      // active-low RESET signal
  input clk,                          // clock signal

  // for debuging/testing purpose
  output [`WORD_SIZE-1:0] num_inst,   // number of instruction during execution
  output [`WORD_SIZE-1:0] output_port // this will be used for a "WWD" instruction
);

    reg readM;
    reg [`WORD_SIZE-1:0] address;
    reg [`WORD_SIZE-1:0] num_inst;
    
    reg [`WORD_SIZE-1:0] instruction;
    //reg [`WORD_SIZE-1:0] output_port;

    wire[`WORD_SIZE-1:0] next_address;
    
    wire[3:0] opcode;
    wire regdest, jump, alusrc, regwrite;
    wire[3:0] aluop;

  // ... fill in the rest of the code
  always@(posedge clk) begin
      if(!reset_n) begin
        readM<=0;
        address<=0;
        num_inst<=0;
        //output_port<=0;
      end
      else begin
        readM<=1;
        num_inst<=num_inst+1;
        end
  end

 always@(inputReady) begin
    readM<=0;
    if(inputReady==1)begin
        instruction<=data;
    end
    if(inputReady==0)begin
    address<=next_address;
    end
 end

  Datapath dp00(address, instruction, regdest, jump, alusrc, regwrite, aluop, inputReady, reset_n, next_address, output_port, opcode);

  Control_unit cu00(opcode, regdest, jump, alusrc, regwrite, aluop);


endmodule
//////////////////////////////////////////////////////////////////////////
