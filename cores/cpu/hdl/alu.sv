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
//   4'b0001 SLL  - Shift Left Logical
//   4'b0010 SLT  - Set Less Than (signed)
//   4'b0011 SLTU - Set Less Than Unsigned
//   4'b0100 XOR  - Bitwise XOR
//   4'b0101 SRL  - Shift Right Logical
//   4'b0110 OR   - Bitwise OR
//   4'b0111 AND  - Bitwise AND
//   4'b1000 SUB  - Subtraction
//   4'b1101 SRA  - Shift Right Arithmetic

`include "cpu_types.vh"

module alu (
    input logic [31:0] i_alu_a,
    input logic [31:0] i_alu_b,
    input alu_op_t i_alu_ctrl,
    output logic [31:0] o_alu_out,
    output logic o_alu_exception
);

  logic [31:0] diff;
  logic [ 4:0] shamt;
  logic [31:0] result;

  assign diff  = i_alu_a - i_alu_b;
  assign shamt = i_alu_b[4:0];

  always_comb begin : alu_result
    unique case (i_alu_ctrl)
      OP_ADD:  result = i_alu_a + i_alu_b;
      OP_SUB:  result = diff;
      OP_SLT: begin
        if (i_alu_a[31] ^ i_alu_b[31]) begin
          result = {31'b0, i_alu_a[31]};
        end else begin
          result = {31'b0, diff[31]};
        end
      end
      OP_SLTU: result = {31'b0, (i_alu_a < i_alu_b)};
      OP_AND:  result = i_alu_a & i_alu_b;
      OP_OR:   result = i_alu_a | i_alu_b;
      OP_XOR:  result = i_alu_a ^ i_alu_b;
      OP_SLL:  result = i_alu_a << shamt;
      OP_SRL:  result = i_alu_a >> shamt;
      OP_SRA:  result = $signed(i_alu_a) >>> shamt;
      default: result = '0;
    endcase
  end

  always_comb begin : alu_controller
    if (i_alu_ctrl == OP_INVALID) begin
      o_alu_exception = '1;
    end else begin
      o_alu_exception = '0;
    end
  end

  assign o_alu_out = result;

endmodule
