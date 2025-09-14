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

// Module  : uart_rx_des
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   UART receiver deserializer module
//   Handles serial-to-parallel conversion with proper timing
//
// Parameters:
//   WORD_WIDTH - Data word width in bits (default: 8)
//   OVERSAMPLING - Oversampling factor (default: 16)

`default_nettype none

module uart_rx_des #(
    parameter WORD_WIDTH   = 8,
    parameter OVERSAMPLING = 16
) (
    input  wire                  i_clk,
    input  wire                  i_rst_n,
    input  wire                  i_tick,
    input  wire                  i_din,
    input  wire                  i_parity,
    output wire [DATA_WIDTH-1:0] o_dout,
    output reg                   o_frame_err,
    output reg                   o_done,
    output reg                   o_active
);

  localparam TICK_MID_VAL = OVERSAMPLING / 2 - 1;
  localparam DATA_WIDTH = WORD_WIDTH + 1;  // parity bit

  localparam [2:0] IDLE = 3'b000, START_BIT = 3'b001, DATA = 3'b010, STOP_BIT = 3'b011;

  reg [2:0] state, state_nxt;

  // internal
  reg [$clog2(OVERSAMPLING)-1:0] tick_ctr, tick_ctr_nxt;
  reg [$clog2(DATA_WIDTH+1)-1:0] bit_ctr, bit_ctr_nxt;
  wire [$clog2(DATA_WIDTH+1)-1:0] N = i_parity ? DATA_WIDTH : WORD_WIDTH;

  // outputs
  reg [DATA_WIDTH-1:0] d, d_nxt;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      state    <= IDLE;
      tick_ctr <= 0;
      bit_ctr  <= 0;
      d        <= 0;
    end
    else begin
      state    <= state_nxt;
      tick_ctr <= tick_ctr_nxt;
      bit_ctr  <= bit_ctr_nxt;
      d        <= d_nxt;
    end
  end

  always @(*) begin
    state_nxt    = state;
    tick_ctr_nxt = tick_ctr;
    bit_ctr_nxt  = bit_ctr;
    d_nxt        = d;
    o_done       = 1'b0;
    o_frame_err  = 1'b0;

    case (state)
      IDLE: begin
        if (~i_din) begin
          state_nxt    = START_BIT;
          tick_ctr_nxt = TICK_MID_VAL;
        end
      end
      START_BIT: begin
        if (i_tick) begin
          tick_ctr_nxt = tick_ctr - 1;
          if (tick_ctr == 0) begin
            state_nxt    = DATA;
            tick_ctr_nxt = OVERSAMPLING - 1;
          end
        end
      end
      DATA: begin
        if (i_tick) begin
          tick_ctr_nxt = tick_ctr - 1;
          if (tick_ctr == 0) begin
            if (bit_ctr == N) begin
              state_nxt   = STOP_BIT;
              bit_ctr_nxt = 0;
            end
            else begin
              bit_ctr_nxt = bit_ctr + 1;
              d_nxt       = {i_din, d[DATA_WIDTH-1 : 1]};
            end
            tick_ctr_nxt = OVERSAMPLING - 1;
          end
        end
      end
      STOP_BIT: begin
        if (i_tick) begin
          if (tick_ctr == 0) begin
            state_nxt = IDLE;
            if (i_din)  // check data line deasserted
              o_done = 1'b1;
            else o_frame_err = 1'b1;
          end
          else tick_ctr_nxt = tick_ctr - 1;
        end
      end
    endcase
  end

  assign o_dout   = d;
  assign o_active = state != IDLE;

endmodule
