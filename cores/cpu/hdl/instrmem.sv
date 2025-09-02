// SIZE = size of memory in bytes

module instrmem #(
    parameter int SIZE = 512
) (
    input clk,
    input rst_n,
    input [31:0] pc_ip,
    output [31:0] instr_op
);

  reg [7:0] mem[SIZE-1];
  reg [31:0] next_instr;

  integer i;

  initial begin
    if ($value$plusargs("IMEM_PRELOAD=%s", filename)) begin
      $readmemh(filename, mem);
      $display("Loaded memory from %s", filename);
    end else begin
      foreach (mem[i]) mem[i] = '0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin : fetch_instruction
    if (~rst_n) begin
      next_instr <= 32'h00000013;  //  NOP
    end else begin
      next_instr <= {mem[pc_ip+3], mem[pc_ip+2], mem[pc_ip+1], mem[pc_ip]};
    end
  end

  assign instr_op = next_instr;

endmodule
