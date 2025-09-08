/*
this can be implemented as BRAM on FPGA
*/

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
