/* memory access to write-back */
module q4q5 #(
    parameter CTRL_WIDTH = 16
) (
    input                   clk,
    input                   rst_n,
    input  [          31:0] alu_out_ip,
    output [          31:0] alu_out_op,
    input  [          31:0] mem_rdata_ip,
    output [          31:0] mem_rdata_op,
    input  [           4:0] reg_wr_port_ip,
    output [           4:0] reg_wr_port_op,
    input  [CTRL_WIDTH-1:0] ctrl_q4_ip,
    output [CTRL_WIDTH-1:0] ctrl_q4_op,
    input  [          31:0] instr_ip,
    output [          31:0] instr_op
);

  reg [          31:0] next_reg_wr_port;
  reg [          31:0] next_alu_out;
  reg [          31:0] next_mem_rdata;
  reg [CTRL_WIDTH-1:0] next_ctrl_q4;
  reg [          31:0] next_instr;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      next_alu_out     <= 0;
      next_mem_rdata   <= 0;
      next_reg_wr_port <= 0;
      next_ctrl_q4     <= 0;
      next_instr       <= 32'h00000013;  //  NOP;
    end else begin
      next_alu_out     <= alu_out_ip;
      next_mem_rdata   <= mem_rdata_ip;
      next_reg_wr_port <= reg_wr_port_ip;
      next_ctrl_q4     <= ctrl_q4_ip;
      next_instr       <= instr_ip;
    end
  end

  assign alu_out_op     = next_alu_out;
  assign mem_rdata_op   = next_mem_rdata;
  assign reg_wr_port_op = next_reg_wr_port;
  assign ctrl_q4_op     = next_ctrl_q4;
  assign instr_op       = next_instr;

endmodule
