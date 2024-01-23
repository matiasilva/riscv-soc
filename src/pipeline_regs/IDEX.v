
module IDEX 
	#(parameter CTRL_WIDTH = 16)
	(
	input clk,
	input rst_n,
	input [31:0] pc_incr_i,
	input [31:0] rd_data1_i,
	input [31:0] rd_data2_i,
	input [4:0] wr_reg_i,
	input [31:0] imm_se_i,
	input [CTRL_WIDTH - 1:0] ctrl_q2_i,
	input [3:0] funct_i,
	output [31:0] pc_incr_o,
	output [31:0] rd_data1_o,
	output [31:0] rd_data2_o,
	output [4:0] wr_reg_o,
	output [31:0] imm_se_o,
	output [CTRL_WIDTH - 1:0] ctrl_q2_o,
	output [3:0] funct_o
);

	reg [31:0] next_pc_incr;
	reg [31:0] next_rdata1;
	reg [31:0] next_rdata2;
	reg [4:0] next_wr_reg;
	reg [31:0] next_imm_se;
	reg [CTRL_WIDTH - 1: 0] next_ctrl_q2;
	reg [3:0] next_funct;

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			next_pc_incr <= 0;
			next_rdata1  <= 0;
			next_rdata2  <= 0;
			next_wr_reg <= 0;
			next_imm_se  <= 0;
			next_ctrl_q2 <= 0;
			next_funct <= 0;
		end else begin
			next_pc_incr <= pc_incr_i;
			next_rdata1  <= rd_data1_i;
			next_rdata2  <= rd_data2_i;
			next_wr_reg <= wr_reg_i;
			next_imm_se  <= imm_se_i;
			next_ctrl_q2 <= ctrl_q2_i;
			next_funct <= funct_i;
		end
	end

	assign pc_incr_o  = next_pc_incr;
	assign rd_data1_o = next_rdata1;
	assign rd_data2_o = next_rdata2;
	assign wr_reg_o  = next_wr_reg;
	assign imm_se_o   = next_imm_se;
	assign ctrl_q2_o  = next_ctrl_q2;
	assign funct_o = next_funct;

endmodule