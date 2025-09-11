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

// Module  : memory
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Data memory module for RISC-V processor
//   Can be implemented as BRAM on FPGA for efficient synthesis
//
// Parameters:
//   PRELOAD - Enable memory preloading (0/1)
//   PRELOAD_FILE - Path to preload file

module memory #(
    parameter PRELOAD = 0,
    parameter PRELOAD_FILE = ""
) (
    input i_rst_n,
    input i_clk,
    input i_ctrl_mem_ren,
    input i_ctrl_mem_wren,
    input [31:0] i_mem_addr,
    input [31:0] i_mem_wdata,
    output [31:0] o_mem_rdata
);

  localparam MEM_SIZE = 512;

  // 512 bytes, 128 words
  reg [7:0] mem[MEM_SIZE - 1:0];
  reg [31:0] next_rdata;

  integer i;

  initial begin
    if (PRELOAD) begin
      if (PRELOAD_FILE === "") begin
        $display("no preload file provided!");
        $finish;
      end
      $readmemh(PRELOAD_FILE, mem, 0, 31);
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
`ifdef FPGA
      for (i = 0; i < MEM_SIZE; i++) begin
        mem[i] <= 0;
      end
`endif
      next_rdata <= 0;
    end else begin
      if (i_ctrl_mem_ren) begin
        next_rdata <= {mem[i_mem_addr+3], mem[i_mem_addr+2], mem[i_mem_addr+1], mem[i_mem_addr]};
      end else if (i_ctrl_mem_wren) begin
        for (i = 0; i < 4; i++) begin
          mem[i_mem_addr+i] <= i_mem_wdata[i*8+:8];
        end
      end
    end
  end

  assign o_mem_rdata = next_rdata;

endmodule
