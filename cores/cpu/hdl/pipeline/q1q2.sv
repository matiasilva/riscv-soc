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

// Module  : q1q2
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Pipeline register between Q1 (instruction fetch) and Q2 (instruction decode/register file access)
//
// Parameters:
//   None

`include "cpu_types.vh"

module q1q2 (
    input         i_clk,
    input         i_rst_n,
    input  q1q2_t i_q1q2,
    output q1q2_t o_q1q2
);

  q1q2_t next_q1q2;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      next_q1q2 <= '{
          insn: 32'h00000013,  // NOP
          pc: '0,
          pc_incr: '0
      };
    end
    else begin
      next_q1q2 <= i_q1q2;
    end
  end

  assign o_q1q2 = next_q1q2;

endmodule
