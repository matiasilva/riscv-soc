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

// Module  : flag_buf
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Single word buffer with flag for UART data buffering
//   Provides simple buffering with valid/ready handshaking
//
// Parameters:
//   WORD_WIDTH - Data word width in bits (default: 8)

`default_nettype none

module flag_buf #(
   parameter WORD_WIDTH = 8
) (
   input wire i_clk,
   input wire i_rst_n,

   input wire i_flag_set,
   input wire i_flag_clear,
   input wire [WORD_WIDTH-1:0] i_din,

   output reg o_flag,
   output wire [WORD_WIDTH-1:0] o_dout,
   output reg o_overflow_err
);

reg [WORD_WIDTH-1:0] data_buf;

always @(posedge i_clk or negedge i_rst_n) begin
   if (~i_rst_n) begin
      data_buf <= 0;
      o_flag <= 1'b0;
      o_overflow_err <= 1'b0;
   end else begin
      if (i_flag_set) begin
         o_flag <= 1'b1;
         data_buf <= i_din;
         if (o_flag)
            o_overflow_err <= 1'b1;
      end else if (i_flag_clear) begin
         o_overflow_err <= 1'b0;
         o_flag <= 1'b0;
      end
   end
end

assign o_dout = data_buf;

endmodule
