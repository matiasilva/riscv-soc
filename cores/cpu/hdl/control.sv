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

// Module  : control
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Emits control signals for the downstream CPU pipelines based on
//   instruction decode rules
//
// Parameters:
//   CTRL_WIDTH - The width of the output control signal
//
// Signals:
//  aluop
//  mem_re
//  mem_we
//  reg_wr_en     - enable writeback to regfile
//  is_mem_to_reg - select whether ALU result or memory read is written to regfile
//  is_branch
//  is_jal
//  is_jalr
//  alusrc        - select sign-extended immediate OR rs2 field of instruction

module control #(
    parameter int CTRL_WIDTH = 16
) (
    input [6:0] i_opcode,
    output [CTRL_WIDTH - 1:0] o_ctrl
);

  typedef enum logic [6:0] {
    OP_RTYPE  = 7'b0110011,
    OP_ITYPE  = 7'b0010011,
    OP_LOAD   = 7'b0000011,
    OP_STORE  = 7'b0100011,
    OP_JAL    = 7'b1101111,
    OP_JALR   = 7'b1100111,
    OP_BRANCH = 7'b1100011
  } opcode_t;

  typedef enum logic [1:0] {
    ALUOP_ADD   = 2'b00,
    ALUOP_SLTU  = 2'b01,
    ALUOP_FUNCT = 2'b10
  } aluop_t;

  typedef enum logic {
    ALUSRC_IMM = 1'b0,
    ALUSRC_REG = 1'b1
  } alusrc_t;


  logic [1:0] aluop;
  logic mem_re;
  logic mem_we;
  logic reg_wr_en;
  logic is_mem_to_reg;
  logic is_branch;
  logic is_jal;  // q2
  logic is_jalr;  // q3
  logic alusrc;

  always_comb begin
    mem_re        = 1'b0;
    mem_we        = 1'b0;
    reg_wr_en     = 1'b0;
    is_mem_to_reg = 1'b0;
    is_branch     = 1'b0;
    is_jal        = 1'b0;
    alusrc        = ALUSRC_IMM;
    aluop         = ALUOP_ADD;
    case (i_opcode)
      OP_RTYPE: begin
        reg_wr_en = 1'b1;
        alusrc    = ALUSRC_REG;
        aluop     = ALUOP_FUNCT;
      end
      OP_ITYPE: begin
        reg_wr_en = 1'b1;
        aluop     = ALUOP_FUNCT;
      end
      OP_LOAD: begin
        mem_re        = 1'b1;
        reg_wr_en     = 1'b1;
        is_mem_to_reg = 1'b1;
      end
      OP_STORE: begin
        mem_we = 1'b1;
      end
      OP_JAL: begin
        is_jal = 1'b1;
        reg_wr_en = 1'b1;
      end
    endcase
  end

  wire q2_bits = is_jal;
  wire [2:0] q3_bits = {aluop, alusrc};
  wire [2:0] q4_bits = {is_branch, mem_re, mem_we};
  wire [1:0] q5_bits = {reg_wr_en, is_mem_to_reg};

  assign o_ctrl = {7'b0, q2_bits, q3_bits, q4_bits, q5_bits};

endmodule
