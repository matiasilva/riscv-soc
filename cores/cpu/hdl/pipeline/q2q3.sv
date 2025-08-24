/* instruction decode/register file access to execute/ALU */
module q2q3 #(
    parameter CTRL_WIDTH = 16
) (
    input                   clk,
    input                   rst_n,
    input  [          31:0] pc_ip,
    output [          31:0] pc_op,
    input  [          31:0] reg_rd_data1_ip,
    output [          31:0] reg_rd_data1_op,
    input  [          31:0] reg_rd_data2_ip,
    output [          31:0] reg_rd_data2_op,
    input  [           4:0] reg_wr_port_ip,
    output [           4:0] reg_wr_port_op,
    input  [CTRL_WIDTH-1:0] ctrl_q2_ip,
    output [CTRL_WIDTH-1:0] ctrl_q2_op,
    input  [          31:0] instr_ip,
    output [          31:0] instr_op,
    input  [          31:0] pc_incr_ip,
    output [          31:0] pc_incr_op

);

  reg [          31:0] next_pc;
  reg [          31:0] next_pc_incr;

  reg [          31:0] next_reg_rd_data1;
  reg [          31:0] next_reg_rd_data2;
  reg [           4:0] next_reg_wr_port;
  reg [CTRL_WIDTH-1:0] next_ctrl_q2;
  reg [          31:0] next_instr;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      next_pc           <= 0;
      next_reg_rd_data1 <= 0;
      next_reg_rd_data2 <= 0;
      next_reg_wr_port  <= 0;
      next_ctrl_q2      <= 0;
      next_instr        <= 32'h00000013;  //  NOP;
      next_pc_incr      <= 0;

    end else begin
      next_pc           <= pc_ip;
      next_reg_rd_data1 <= reg_rd_data1_ip;
      next_reg_rd_data2 <= reg_rd_data2_ip;
      next_reg_wr_port  <= reg_wr_port_ip;
      next_ctrl_q2      <= ctrl_q2_ip;
      next_instr        <= instr_ip;
      next_pc_incr      <= pc_incr_ip;

    end
  end

  assign pc_op           = next_pc;
  assign pc_incr_op      = next_pc_incr;

  assign reg_rd_data1_op = next_reg_rd_data1;
  assign reg_rd_data2_op = next_reg_rd_data2;
  assign reg_wr_port_op  = next_reg_wr_port;
  assign ctrl_q2_op      = next_ctrl_q2;
  assign instr_op        = next_instr;
endmodule
