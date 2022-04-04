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
    reg [`WORD_SIZE-1:0] num_inst;
    reg [`WORD_SIZE-1:0] instruction;
    
    wire[3:0] opcode;
    wire[5:0] funct;
    wire regdest, jump, alusrc1, alusrc2, regwrite, mem_out;
    wire[3:0] aluop;

  // ... fill in the rest of the code
  
  always@(*)begin
      //reset
      if(!reset_n) begin
        readM<=0;
        num_inst<=-1;
        instruction<=16'h4000;  //ADI $0, $0, 0 (reset instruction)
      end
  end

  always@(posedge clk) begin
      if(reset_n) begin
        readM<=1;                 //start readm
        num_inst<=num_inst+1;
      end
  end

 always@(posedge inputReady) begin
    if(reset_n)begin
        readM<=0;                   //end readm
        instruction<=data;      //save instruction
    end
 end

  Datapath dp00( 
    .instruction(instruction), 
    .regdest(regdest), 
    .jump(jump), 
    .alusrc1(alusrc1),
    .alusrc2(alusrc2), 
    .regwrite(regwrite), 
    .aluop(aluop), 
    .mem_out(mem_out),
    .clk(clk), 
    .reset_n(reset_n),
    .output_port(output_port), 
    .opcode(opcode),
    .funct(funct),
    .PC(address)
  );

  Control_unit cu00(
    .opcode(opcode), 
    .funct(funct), 
    .regdest(regdest), 
    .jump(jump), 
    .alusrc1(alusrc1),
    .alusrc2(alusrc2), 
    .regwrite(regwrite), 
    .aluop(aluop),
    .mem_out(mem_out)
  );


endmodule
//////////////////////////////////////////////////////////////////////////
