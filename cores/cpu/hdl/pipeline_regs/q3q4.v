/* execute/ALU to memory access */
module q3q4 #(
    parameter CTRL_WIDTH = 16
) (
    input                      clk,
    input                      rst_n,
    input  [             31:0] pc_next_ip,
    output [             31:0] pc_next_op,
    input  [             31:0] alu_out_ip,
    output [             31:0] alu_out_op,
    input  [             31:0] reg_rd_data2_ip,
    output [             31:0] reg_rd_data2_op,
    input  [              4:0] reg_wr_port_ip,
    output [              4:0] reg_wr_port_op,
    input  [CTRL_WIDTH -1 : 0] ctrl_q3_ip,
    output [CTRL_WIDTH -1 : 0] ctrl_q3_op,
    input  [             31:0] instr_ip,
    output [             31:0] instr_op
);

  reg [           31:0] next_pc_next;
  reg [           31:0] next_alu_out;
  reg [           31:0] next_reg_rd_data2;
  reg [           31:0] next_reg_wr_port;
  reg [CTRL_WIDTH -1:0] next_ctrl_q3;
  reg [           31:0] next_instr;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      next_pc_next <= 0;
      next_alu_out <= 0;
      next_reg_wr_port <= 0;
      next_reg_rd_data2 <= 0;
      next_ctrl_q3 <= 0;
      next_instr <= 32'h00000013;  //  NOP;
    end else begin
      next_pc_next <= pc_next_ip;
      next_alu_out <= alu_out_ip;
      next_reg_rd_data2 <= reg_rd_data2_ip;
      next_reg_wr_port <= reg_wr_port_ip;
      next_ctrl_q3 <= ctrl_q3_ip;
      next_instr <= instr_ip;
    end
  end

  assign pc_next_op = next_pc_next;
  assign alu_out_op = next_alu_out;
  assign reg_rd_data2_op = next_reg_rd_data2;
  assign reg_wr_port_op = next_reg_wr_port;
  assign ctrl_q3_op = next_ctrl_q3;
  assign instr_op = next_instr;

endmodule
