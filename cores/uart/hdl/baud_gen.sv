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

// Module  : baud_gen
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Configurable baud rate generator for UART communication
//   Generates timing ticks for UART transmission and reception
//
// Parameters:
//   OVERSAMPLING - Oversampling factor (default: 16)
//   BAUD_RATE - Target baud rate (default: 115200)
//   FREQ - Input clock frequency in Hz (default: 50MHz)

`default_nettype none

module baud_gen #(
   parameter OVERSAMPLING = 16,
   parameter BAUD_RATE = 115200,
   parameter FREQ = 50000000
) (
   input wire i_clk,
   input wire i_rst_n,

   output wire o_tick
);

localparam OVERSAMLING_FREQ = OVERSAMPLING * BAUD_RATE;
localparam M =  (FREQ + OVERSAMLING_FREQ - 1) / OVERSAMLING_FREQ; // (A+B-1)/B rounds up after truncation
localparam N = $clog2(M);

reg [N-1:0] cnt;
wire [N-1:0] cnt_next;

always @(posedge i_clk or negedge i_rst_n)
   if (~i_rst_n)
      cnt <= 0;
   else
      cnt <= cnt_next;

assign cnt_next = (cnt == (M - 1)) ? 0 : cnt + 1;

assign o_tick = cnt == (M - 1);

endmodule
