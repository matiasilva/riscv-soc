// SIZE = size of memory in bytes

module instrmem #(
    parameter int SIZE = 512
) (
    input logic i_clk,
    input logic i_rst_n,
    input logic [31:0] i_pc,
    output logic [31:0] o_instr,
    output logic o_imem_exception
);

  reg [7:0] mem[SIZE];
  reg [31:0] next_instr;
  logic addr;

  logic align_bits;
  assign align_bits = i_pc[1:0];

  int i;
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
      o_imem_exception = 1'b1;
      addr = '0;
    end else begin
      o_imem_exception = 1'b0;
      addr = i_pc;
    end
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin : fetch_instruction
    if (~i_rst_n) begin
      next_instr <= 32'h00000013;  //  NOP
    end else begin
      next_instr <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
    end
  end

  assign o_instr = next_instr;

endmodule
