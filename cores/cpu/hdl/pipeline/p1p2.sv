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

// Module  : p1p2
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Pipeline register between P1 (instruction fetch) and P2 (instruction decode/register file access)
//
// Parameters:
//   None

`include "cpu_types.vh"

module p1p2 (
    input  logic  i_clk,
    input  logic  i_rst_n,
    input  p1p2_t i_p1p2,
    output p1p2_t o_p1p2
);

  p1p2_t p1p2_next;

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      p1p2_next <= '{pc: '0, pc_plus_4: '0};
    end else begin
      p1p2_next <= i_p1p2;
    end
  end

  assign o_p1p2 = p1p2_next;

endmodule
