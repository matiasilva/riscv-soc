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

// Module  : aluctrl
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   ALU control unit: remaps all instruction execute operations to valid alu_ops
//
// Control Mapping:
//   aluop[1:0]:
//     00 -> ADD (for lw, sw operations)
//     01 -> SLTU (for beq operations)
//     10 -> Use {funct7[5], funct3} field (passthrough for R-type/I-type)
//      ADDI/ADD: funct3 = 000
//      SLTI/SLT: funct3 = 010
//      ANDI/AND: funct3 = 111
//      ORI/OR:   funct3 = 110
//     11 -> Not implemented
//
// Parameters:
//   None

`include "cpu_types.vh"

module aluctrl (
    input alu_ctrl_t i_aluop,
    input logic [2:0] i_funct3,
    input logic i_funct7_5,
    output alu_op_t o_alu_ctrl
);

  alu_op_t ctrl;

  always_comb begin
    unique case (i_aluop)
      ALUOP_ADD: begin
        ctrl = OP_ADD;
      end
      ALUOP_SLTU: begin
        ctrl = OP_SLTU;
      end
      ALUOP_FUNCT: begin
        ctrl = alu_op_t'({i_funct7_5, i_funct3});
      end
      ALUOP_INVALID: begin
        ctrl = OP_INVALID;
      end
    endcase
  end

  assign o_alu_ctrl = ctrl;

endmodule
