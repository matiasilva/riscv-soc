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
// Signals:
//  aluop
//  mem_re
//  mem_we
//  reg_wr_en     - enable writeback to regfile
//  is_mem_to_reg - select whether ALU result or memory read is written to regfile
//  is_branch
//  is_jal
//  is_jalr
//  alu_src       - select sign-extended immediate OR rs2 field of instruction
`include "cpu_types.vh"

module control (
    input  opcode_t   i_opcode,
    output cpu_ctrl_t o_ctrl
);

  alu_ctrl_t aluop;
  logic mem_re;
  logic mem_we;
  logic reg_wr_en;
  logic is_mem_to_reg;
  logic is_branch;
  logic is_jal;  // q2
  logic is_jalr;  // q3
  alu_src_t alu_src;

  always_comb begin
    mem_re        = '0;
    mem_we        = '0;
    reg_wr_en     = '0;
    is_mem_to_reg = '0;
    is_branch     = '0;
    is_jal        = '0;
    is_jalr       = '0;
    alu_src       = ALUSRC_IMM;
    aluop         = ALUOP_ADD;

    unique case (i_opcode)
      OP_RTYPE: begin
        reg_wr_en = '1;
        alu_src   = ALUSRC_REG;
        aluop     = ALUOP_FUNCT;
      end
      OP_ITYPE: begin
        reg_wr_en = '1;
        aluop     = ALUOP_FUNCT;
      end
      OP_LOAD: begin
        mem_re        = '1;
        reg_wr_en     = '1;
        is_mem_to_reg = '1;
      end
      OP_STORE: begin
        mem_we = '1;
      end
      OP_BRANCH: begin
        is_branch = '1;
      end
      OP_JAL: begin
        is_jal    = '1;
        reg_wr_en = '1;
      end
      OP_JALR: begin
        is_jalr   = '1;
        reg_wr_en = '1;
      end
      default: begin
      end
    endcase

    o_ctrl = '{
        q2: '{is_jal: is_jal},
        q3: '{alu_ctrl: aluop, alu_src: alu_src},
        q4: '{is_branch: is_branch, mem_re: mem_re, mem_we: mem_we},
        q5: '{reg_wr_en: reg_wr_en, is_mem_to_reg: is_mem_to_reg}
    };
  end

endmodule
