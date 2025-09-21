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

// Module  : insnmem
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Instruction memory module for RISC-V processor
//   Provides read-only access to instruction storage with exception handling
//
// Parameters:
//   SIZE - Memory size in bytes (default: 512)
`include "cpu_types.vh"

module insnmem #(
    parameter int SIZE = 512
) (
    input  logic         i_clk,
    input  logic         i_rst_n,
    input  logic  [31:0] i_pc,
    output insn_t        o_insn,
    output logic         o_imem_exception
);

  logic [ 7:0] mem        [SIZE];
  logic [31:0] next_insn;
  logic [31:0] addr;

  logic [ 1:0] align_bits;
  assign align_bits = i_pc[1:0];

  string filename;

  initial begin
    if ($value$plusargs("IMEM_PRELOAD_FILE=%s", filename)) begin
      $readmemh(filename, mem);
      $display("Loaded memory from %s", filename);
    end else begin
      foreach (mem[i]) mem[i] = '0;
    end
  end

  always_comb begin : imem_controller
    if (align_bits == 2'b0) begin
      o_imem_exception = 1'b0;
      addr             = i_pc;
    end else begin
      o_imem_exception = 1'b1;
      addr             = '0;
    end
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin : fetch_insn
    if (~i_rst_n) begin
      next_insn <= 32'h00000013;  //  NOP
    end else begin
      next_insn <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
    end
  end

  assign o_insn = next_insn;

endmodule
