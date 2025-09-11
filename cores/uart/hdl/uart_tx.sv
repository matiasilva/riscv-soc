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

// Module  : uart_tx
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   UART transmitter module with configurable word width and baud rate
//   Serializes parallel data for UART transmission
//
// Parameters:
//   WORD_WIDTH - Data word width in bits (default: 8)
//   OVERSAMPLING - Oversampling factor (default: 16)
//   BAUD_RATE - Target baud rate (default: 115200)

module uart_tx #(
   parameter WORD_WIDTH = 8,
   parameter OVERSAMPLING = 16,
   parameter BAUD_RATE = 115200
) (
   input wire i_clk,
   input wire i_rst_n,
   input wire i_tick,

   // write interface
   input wire [WORD_WIDTH-1:0] i_wr_data,
   input wire i_wr_valid,
   output wire o_wr_ready,

   // config
   wire i_parity_cfg,

   output wire o_dout
);

wire [WORD_WIDTH-1:0] word;
wire ser_tx_start;
wire ser_active;
wire flag;
wire flag_set;
wire flag_clear;

wire overflow_err;

// configuration update
always @(posedge i_clk or negedge i_rst_n) begin
   if (~i_rst_n) begin
      parity <= 1'b0;
   end else begin
      if (parity != i_parity_cfg && !ser_active)
         parity <= i_parity_cfg;
   end
end

uart_tx_ser #( .WORD_WIDTH(WORD_WIDTH), .OVERSAMPLING(OVERSAMPLING) ) uart_tx_ser0 (
   .i_clk     (i_clk),
   .i_rst_n   (i_rst_n),
   .i_tick    (i_tick),
   .i_din     (word),
   .i_tx_start(flag),
   .i_parity  (parity),
   .o_dout    (o_dout),
   .o_active  (ser_active)
);


flag_buf #( .WORD_WIDTH(WORD_WIDTH) ) flag_buf0 (
   .i_clk         (i_clk),
   .i_rst_n       (i_rst_n),
   .i_flag_set    (flag_set),
   .i_flag_clear  (flag_clear),
   .i_din         (i_wr_data),
   .o_flag        (flag),
   .o_dout        (word),
   .o_overflow_err(overflow_err)
);

assign o_wr_ready = !flag;

endmodule
