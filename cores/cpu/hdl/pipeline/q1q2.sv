/* instruction fetch to instruction decode/register file access */
module q1q2 (
    input i_clk,
    input i_rst_n,
    input [31:0] i_instr,
    input [31:0] i_pc,
    input [31:0] i_pc_incr,
    output [31:0] o_instr,
    output [31:0] o_pc,
    output [31:0] o_pc_incr
);

  reg [31:0] next_instr;
  reg [31:0] next_pc;
  reg [31:0] next_pc_incr;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      next_instr <= 32'h00000013; //NOP
      next_pc <= 0;
      next_pc_incr <= 0;
    end else begin
      next_instr   <= i_instr;
      next_pc <= i_pc;
      next_pc_incr <= i_pc_incr;
    end
  end

  assign o_instr   = next_instr;
  assign o_pc = next_pc;
  assign o_pc_incr = next_pc_incr;

endmodule
