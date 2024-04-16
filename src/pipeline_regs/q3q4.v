/* execute/ALU to memory access */
module q3q4 #(
    parameter CTRL_WIDTH = 16
) (
    input                      clk,
    input                      rst_n,
    input  [             31:0] pc_next_i,
    input  [             31:0] alu_out_i,
    input  [             31:0] reg_rd_data2_i,
    input  [              4:0] reg_wr_port_i,
    input  [CTRL_WIDTH -1 : 0] ctrl_q3_i,
    output [             31:0] pc_next_o,
    output [             31:0] alu_out_o,
    output [             31:0] reg_rd_data2_o,
    output [              4:0] reg_wr_port_o,
    output [CTRL_WIDTH -1 : 0] ctrl_q3_o
);

  reg [           31:0] next_pc_next;
  reg [           31:0] next_alu_out;
  reg [           31:0] next_reg_rd_data2;
  reg [           31:0] next_reg_wr_port;
  reg [CTRL_WIDTH -1:0] next_ctrl_q3;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      next_pc_next <= 0;
      next_alu_out <= 0;
      next_reg_wr_port <= 0;
      next_reg_rd_data2 <= 0;
      next_ctrl_q3 <= 0;
    end else begin
      next_pc_next <= pc_next_i;
      next_alu_out <= alu_out_i;
      next_reg_rd_data2 <= reg_rd_data2_i;
      next_reg_wr_port <= reg_wr_port_i;
      next_ctrl_q3 <= ctrl_q3_i;
    end
  end

  assign pc_next_o = next_pc_next;
  assign alu_out_o = next_alu_out;
  assign reg_rd_data2_o = next_reg_rd_data2;
  assign reg_wr_port_o = next_reg_wr_port;
  assign ctrl_q3_o = next_ctrl_q3;

endmodule
