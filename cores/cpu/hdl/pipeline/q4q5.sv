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

// Module  : q4q5
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Pipeline register between Q4 (memory access) and Q5 (write-back)
//
// Parameters:
//   CTRL_WIDTH - Width of control signal bus

module q4q5 #(
    parameter CTRL_WIDTH = 16
) (
    input                   i_clk,
    input                   i_rst_n,
    input  [          31:0] i_alu_out,
    output [          31:0] o_alu_out,
    input  [          31:0] i_mem_rdata,
    output [          31:0] o_mem_rdata,
    input  [           4:0] i_reg_wr_port,
    output [           4:0] o_reg_wr_port,
    input  [CTRL_WIDTH-1:0] i_ctrl_q4,
    output [CTRL_WIDTH-1:0] o_ctrl_q4,
    input  [          31:0] i_instr,
    output [          31:0] o_instr
);

  reg [          31:0] next_reg_wr_port;
  reg [          31:0] next_alu_out;
  reg [          31:0] next_mem_rdata;
  reg [CTRL_WIDTH-1:0] next_ctrl_q4;
  reg [          31:0] next_instr;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      next_alu_out     <= 0;
      next_mem_rdata   <= 0;
      next_reg_wr_port <= 0;
      next_ctrl_q4     <= 0;
      next_instr       <= 32'h00000013;  //  NOP;
    end else begin
      next_alu_out     <= i_alu_out;
      next_mem_rdata   <= i_mem_rdata;
      next_reg_wr_port <= i_reg_wr_port;
      next_ctrl_q4     <= i_ctrl_q4;
      next_instr       <= i_instr;
    end
  end

  assign o_alu_out     = next_alu_out;
  assign o_mem_rdata   = next_mem_rdata;
  assign o_reg_wr_port = next_reg_wr_port;
  assign o_ctrl_q4     = next_ctrl_q4;
  assign o_instr       = next_instr;

endmodule
