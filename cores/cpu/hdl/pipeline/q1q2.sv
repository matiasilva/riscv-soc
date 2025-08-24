/* instruction fetch to instruction decode/register file access */
module q1q2 (
    input clk,
    input rst_n,
    input [31:0] instr_ip,
    input [31:0] pc_ip,
    input [31:0] pc_incr_ip,
    output [31:0] instr_op,
    output [31:0] pc_op,
    output [31:0] pc_incr_op
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
      next_instr   <= instr_ip;
      next_pc <= pc_ip;
      next_pc_incr <= pc_incr_ip;
    end
  end

  assign instr_op   = next_instr;
  assign pc_op = next_pc;
  assign pc_incr_op = next_pc_incr;

endmodule
