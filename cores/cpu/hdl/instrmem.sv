// SIZE = size of memory in bytes

module instrmem #(
    parameter int SIZE = 512
) (
    input i_clk,
    input i_rst_n,
    input [31:0] i_pc,
    output [31:0] o_instr
);

  reg [7:0] mem[SIZE-1];
  reg [31:0] next_instr;

  integer i;
  string filename;

  initial begin
    if ($value$plusargs("IMEM_PRELOAD_FILE=%s", filename)) begin
      $readmemh(filename, mem);
      $display("Loaded memory from %s", filename);
    end else begin
      foreach (mem[i]) mem[i] = '0;
    end
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin : fetch_instruction
    if (~i_rst_n) begin
      next_instr <= 32'h00000013;  //  NOP
    end else begin
      next_instr <= {mem[i_pc+3], mem[i_pc+2], mem[i_pc+1], mem[i_pc]};
    end
  end

  assign o_instr = next_instr;

endmodule
