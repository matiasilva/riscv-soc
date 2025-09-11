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

// Module  : uart_tx_ser
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   UART transmitter serializer module
//   Handles parallel-to-serial conversion with proper timing
//
// Parameters:
//   WORD_WIDTH - Data word width in bits (default: 8)
//   OVERSAMPLING - Oversampling factor (default: 16)

`default_nettype none

module uart_tx_ser #(
   parameter WORD_WIDTH = 8,
   parameter OVERSAMPLING = 16
) (
   input wire i_clk,
   input wire i_rst_n,
   input wire i_tick,

   // data
   input wire [WORD_WIDTH-1:0] i_din,
   input wire i_tx_start,
   output reg o_dout,

   // config & flags
   input wire i_parity,
   output wire o_active
);

localparam DATA_WIDTH = WORD_WIDTH + 1; // parity

localparam [2:0]
   IDLE = 3'b000,
   START_BIT = 3'b001,
   DATA = 3'b010,
   STOP_BIT = 3'b011;

reg [2:0] state, state_nxt;
reg [DATA_WIDTH-1:0] d, d_nxt;
reg [$clog2(OVERSAMPLING)-1:0] tick_ctr, tick_ctr_nxt;
reg [$clog2(DATA_WIDTH+1)-1:0] bit_ctr, bit_ctr_nxt;

wire hamming = ~(^i_din);
wire [$clog2(DATA_WIDTH+1)-1:0] N = i_parity ? DATA_WIDTH : WORD_WIDTH;

always @(posedge i_clk or negedge i_rst_n) begin
   if (~i_rst_n) begin
      d <= 0;
      state <= IDLE;
   end else begin
      d <= d_nxt;
      state <= state_nxt;
      tick_ctr <= tick_ctr_nxt;
      bit_ctr <= bit_ctr_nxt;
   end
end

always @(*) begin
   state_nxt = state;
   d_nxt = d;
   tick_ctr_nxt = tick_ctr;
   bit_ctr_nxt = bit_ctr;

   o_dout = 1'b0;
   case (state)
      IDLE: begin
         if (i_tx_start) begin
            tick_ctr_nxt = OVERSAMPLING - 1;
            state_nxt = START_BIT;
            d_nxt = {hamming, i_din};
         end
      end
      START_BIT: begin
         o_dout = 1'b0;
         if (i_tick) begin
            if (tick_ctr == 0) begin
               state_nxt = DATA;
               tick_ctr_nxt = OVERSAMPLING -1;
               bit_ctr_nxt = N;
            end else
               tick_ctr_nxt = tick_ctr - 1;
         end
      end
      DATA: begin
         o_dout = d[0];
         if (i_tick) begin
            if (tick_ctr == 0) begin
               if (bit_ctr == 0) begin
                  state_nxt = STOP_BIT;
               end else begin
                  bit_ctr_nxt = bit_ctr - 1;
                  d_nxt = d >> 1;
               end
               tick_ctr_nxt = OVERSAMPLING -1;
            end else
               tick_ctr_nxt = tick_ctr - 1;
         end
      end
      STOP_BIT: begin
         o_dout = 1'b1;
         if (i_tick) begin
            if (tick_ctr == 0) begin
               state_nxt = IDLE;
            end else
               tick_ctr_nxt = tick_ctr - 1;
         end
      end
   endcase
end

assign o_active = state != IDLE;

endmodule
