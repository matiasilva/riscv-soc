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

// Module  : log2
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Logarithm base 2 computation using combinational logic
//
// Parameters:
//   WIDTH - Input width in bits
//   LOG_WIDTH - Output width in bits (calculated automatically)

module log2 #(
   parameter WIDTH = 8,
   parameter LOG_WIDTH = $clog2(WIDTH)
) (
   input logic [WIDTH-1:0] i_din,
   output logic [LOG_WIDTH-1:0] o_dout
);

integer i;
always_comb begin : log2_and_or_mux
   o_dout = '0;
   for (i = 0; i < WIDTH; i = i + 1) begin
      o_dout |= {LOG_WIDTH{i_din[i]}} & i[LOG_WIDTH-1:0];
   end
end

endmodule

