/* write-back to next instruction fetch */
module q5q6 #(
    parameter CTRL_WIDTH = 16
) (
    input                   clk,
    input                   rst_n,
    input  [          31:0] alu_out_i,
    output [          31:0] alu_out_o,
    input  [CTRL_WIDTH -1 : 0] ctrl_q5_i,
    output [CTRL_WIDTH -1 : 0] ctrl_q5_o,
    input  [          31:0] instr_i,
    output [          31:0] instr_o
);

  reg [31:0] next_alu_out;
  reg [CTRL_WIDTH -1 : 0] next_ctrl_q5;
  reg [          31:0] next_instr;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      next_ctrl_q5 <= 0;
      next_alu_out     <= 0;
      next_instr       <= 32'h00000013;  //  NOP;
    end else begin
            next_alu_out     <= alu_out_i;
     next_ctrl_q5 <= ctrl_q5_i;
      next_instr       <= instr_i;
    end
  end

  assign ctrl_q5_o = next_ctrl_q5;
  assign instr_o       = next_instr;
  assign alu_out_o     = next_alu_out;


endmodule
