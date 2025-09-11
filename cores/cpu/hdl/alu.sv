// MIT License
//
// Copyright (c) 2025 Matias Wang Silva
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Module  : alu
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Arithmetic Logic Unit supporting RISC-V operations
//   Supports: ADD, SUB, SLT, SLTU, AND, OR, XOR, SLL, SRL, SRA
//
// Control Signals:
//   4'b0000 ADD  - Addition
//   4'b1000 SUB  - Subtraction  
//   4'b0010 SLT  - Set Less Than (signed)
//   4'b0011 SLTU - Set Less Than Unsigned
//   4'b0111 AND  - Bitwise AND
//   4'b0110 OR   - Bitwise OR
//   4'b0100 XOR  - Bitwise XOR
//   4'b0001 SLL  - Shift Left Logical
//   4'b0101 SRL  - Shift Right Logical
//   4'b1101 SRA  - Shift Right Arithmetic

module alu (
    input  [31:0] i_alu_a,
    input  [31:0] i_alu_b,
    input  [ 3:0] i_aluctrl_ctrl,
    output [31:0] o_alu_out
);

  localparam OP_ADD = 4'b0000;
  localparam OP_SUB = 4'b1000;
  localparam OP_SLT = 4'b0010;
  localparam OP_SLTU = 4'b0011;
  localparam OP_AND = 4'b0111;
  localparam OP_OR = 4'b0110;
  localparam OP_XOR = 4'b0100;
  localparam OP_SLL = 4'b0001;
  localparam OP_SRL = 4'b0101;
  localparam OP_SRA = 4'b1101;

  wire [31:0] diff = i_alu_a - i_alu_b;
  wire [ 4:0] shamt = i_alu_b[4:0];

  reg  [31:0] result;

  always @(*) begin
    result = 32'b0;
    case (i_aluctrl_ctrl)
      OP_ADD:  result = i_alu_a + i_alu_b;
      OP_SUB:  result = diff;
      OP_SLT: begin
        if (i_alu_a[31] ^ i_alu_b[31]) begin
          result = i_alu_a[31];
        end else begin
          result = diff[31];
        end
      end
      OP_SLTU: result = i_alu_a < i_alu_b;
      OP_AND:  result = i_alu_a & i_alu_b;
      OP_OR:   result = i_alu_a | i_alu_b;
      OP_XOR:  result = i_alu_a ^ i_alu_b;
      OP_SLL:  result = i_alu_a << shamt;
      OP_SRL:  result = i_alu_a >> shamt;
      OP_SRA:  result = $signed(i_alu_a) >>> shamt;
    endcase
  end

  assign o_alu_out = result;

endmodule
