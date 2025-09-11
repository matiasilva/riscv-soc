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

// Module  : q2q3
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Pipeline register between Q2 (instruction decode/register file access) and Q3 (execute/ALU)
//
// Parameters:
//   CTRL_WIDTH - Width of control signal bus

module q2q3 #(
    parameter CTRL_WIDTH = 16
) (
    input                   i_clk,
    input                   i_rst_n,
    input  [          31:0] i_pc,
    output [          31:0] o_pc,
    input  [          31:0] i_reg_rd_data1,
    output [          31:0] o_reg_rd_data1,
    input  [          31:0] i_reg_rd_data2,
    output [          31:0] o_reg_rd_data2,
    input  [           4:0] i_reg_wr_port,
    output [           4:0] o_reg_wr_port,
    input  [CTRL_WIDTH-1:0] i_ctrl_q2,
    output [CTRL_WIDTH-1:0] o_ctrl_q2,
    input  [          31:0] i_instr,
    output [          31:0] o_instr,
    input  [          31:0] i_pc_incr,
    output [          31:0] o_pc_incr

);

  reg [          31:0] next_pc;
  reg [          31:0] next_pc_incr;

  reg [          31:0] next_reg_rd_data1;
  reg [          31:0] next_reg_rd_data2;
  reg [           4:0] next_reg_wr_port;
  reg [CTRL_WIDTH-1:0] next_ctrl_q2;
  reg [          31:0] next_instr;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      next_pc           <= 0;
      next_reg_rd_data1 <= 0;
      next_reg_rd_data2 <= 0;
      next_reg_wr_port  <= 0;
      next_ctrl_q2      <= 0;
      next_instr        <= 32'h00000013;  //  NOP;
      next_pc_incr      <= 0;

    end else begin
      next_pc           <= i_pc;
      next_reg_rd_data1 <= i_reg_rd_data1;
      next_reg_rd_data2 <= i_reg_rd_data2;
      next_reg_wr_port  <= i_reg_wr_port;
      next_ctrl_q2      <= i_ctrl_q2;
      next_instr        <= i_instr;
      next_pc_incr      <= i_pc_incr;

    end
  end

  assign o_pc           = next_pc;
  assign o_pc_incr      = next_pc_incr;

  assign o_reg_rd_data1 = next_reg_rd_data1;
  assign o_reg_rd_data2 = next_reg_rd_data2;
  assign o_reg_wr_port  = next_reg_wr_port;
  assign o_ctrl_q2      = next_ctrl_q2;
  assign o_instr        = next_instr;
endmodule
