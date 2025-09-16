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

// Module  : p3p4
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Pipeline register between P3 (execute/ALU) and P4 (memory access)
//
// Parameters:
//   None

`include "cpu_types.vh"

module p3p4 (
    input         i_clk,
    input         i_rst_n,
    input  p3p4_t i_p3p4,
    output p3p4_t o_p3p4
);

  p3p4_t next_p3p4;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      next_p3p4 <= '{
          pc_next: '0,
          alu_out: '0,
          reg_rd_data2: '0,
          reg_wr_port: '0,
          ctrl: '0,
          insn: 32'h00000013  // NOP
      };
    end
    else begin
      next_p3p4 <= i_p3p4;
    end
  end

  assign o_p3p4 = next_p3p4;

endmodule
