/* instruction fetch to instruction decode/register file access */
module q1q2 (
    input clk,
    input rst_n,
    input [31:0] instr_i,
    input [31:0] pc_i,
    input [31:0] pc_incr_i,
    output [31:0] instr_o,
    output [31:0] pc_o
    output [31:0] pc_incr_o,
);

  reg [31:0] next_instr;
  reg [31:0] next_pc;
  reg [31:0] next_pc_incr;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      next_instr <= 32'h00000013; //NOP
      next_pc <= 0;
      next_pc_incr <= 0;
    end else begin
      next_instr   <= instr_i;
      next_pc <= pc_i;
      next_pc_incr <= pc_incr_i;
    end
  end

  assign instr_o   = next_instr;
  assign pc_o = next_pc;
  assign pc_incr_o = next_pc_incr;

endmodule
