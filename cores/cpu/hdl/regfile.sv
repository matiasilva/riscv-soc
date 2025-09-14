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

// Module  : regfile
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   32-register register file for RISC-V processor
//   Supports dual-port read and single-port write
//   Register x0 is hardwired to zero
//
// Parameters:
//   XW - Register width in bits (default: 32)

module regfile #(
    parameter int XW = 32
) (
    input  logic          i_clk,
    input  logic          i_rst_n,
    // read interface
    input  logic [   4:0] i_rd_addr1,  // read register 1
    input  logic [   4:0] i_rd_addr2,  // read register 2
    output logic [XW-1:0] o_rd_data1,
    output logic [XW-1:0] o_rd_data2,
    // write interface
    input  logic [XW-1:0] i_wr_data,
    input  logic [   4:0] i_wr_addr,   // write register
    input  logic          i_wr_en
);

  logic   [XW-1:0] x             [31];
  logic   [XW-1:0] rd_data1;
  logic   [XW-1:0] rd_data2;

  logic   [XW-1:0] next_rd_data1;
  logic   [XW-1:0] next_rd_data2;

  integer          i;

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      for (i = 0; i < 31; i++) begin
        x[i] <= '0;
      end
      // next_rd_data1 <= {XW{1'b0}};
      // next_rd_data2 <= {XW{1'b0}};
      rd_data1 <= '0;
      rd_data2 <= '0;
    end
    else begin
      if (i_wr_en) begin
        if (i_wr_addr != 5'b0) begin  // protect against writes to x[0]
          x[i_wr_addr-1] <= i_wr_data;
        end
      end
      rd_data1 <= i_rd_addr1 == 0 ? '0 : x[i_rd_addr1-1];
      rd_data2 <= i_rd_addr2 == 0 ? '0 : x[i_rd_addr2-1];
    end
  end

  // always_ff @(posedge clk) begin
  //   case (rd_addr1_ip)
  //     5'b0: next_rd_data1 <= {XW{1'b0}};
  //     i_wr_addr:
  //     next_rd_data1 <= i_wr_data;  // same cycle read and write supported (hazard prevention)
  //     default: next_rd_data1 <= rd_data1;
  //   endcase
  // end
  //
  // always_ff @(posedge clk) begin
  //   case (rd_addr2_ip)
  //     5'b0:       next_rd_data2 <= {XW{1'b0}};
  //     i_wr_addr: next_rd_data2 <= i_wr_data;
  //     default:    next_rd_data2 <= rd_data2;
  //   endcase
  // end

  assign o_rd_data1 = rd_data1;
  assign o_rd_data2 = rd_data2;

endmodule
