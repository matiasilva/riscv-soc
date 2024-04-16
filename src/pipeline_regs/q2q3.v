/* instruction decode/register file access to execute/ALU */
module q2q3 #(parameter CTRL_WIDTH = 16) (
	input                   clk           ,
	input                   rst_n         ,
	input  [          31:0] pc_incr_i     ,
	output [          31:0] pc_incr_o     ,
	input  [          31:0] reg_rd_data1_i,
	output [          31:0] reg_rd_data1_o,
	input  [          31:0] reg_rd_data2_i,
	output [          31:0] reg_rd_data2_o,
	input  [           4:0] reg_wr_port_i ,
	output [           4:0] reg_wr_port_o ,
	input  [          31:0] imm_se_i      ,
	output [          31:0] imm_se_o      ,
	input  [CTRL_WIDTH-1:0] ctrl_q2_i     ,
	output [CTRL_WIDTH-1:0] ctrl_q2_o     ,
	input  [           3:0] funct_i       ,
	output [           3:0] funct_o
);

	reg [          31:0] next_pc_incr     ;
	reg [          31:0] next_reg_rd_data1;
	reg [          31:0] next_reg_rd_data2;
	reg [           4:0] next_reg_wr_port ;
	reg [          31:0] next_imm_se      ;
	reg [CTRL_WIDTH-1:0] next_ctrl_q2     ;
	reg [           3:0] next_funct       ;

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			next_pc_incr      <= 0;
			next_reg_rd_data1 <= 0;
			next_reg_rd_data2 <= 0;
			next_reg_wr_port  <= 0;
			next_imm_se       <= 0;
			next_ctrl_q2      <= 0;
			next_funct        <= 0;
		end else begin
			next_pc_incr      <= pc_incr_i;
			next_reg_rd_data1 <= reg_rd_data1_i;
			next_reg_rd_data2 <= reg_rd_data2_i;
			next_reg_wr_port  <= reg_wr_port_i;
			next_imm_se       <= imm_se_i;
			next_ctrl_q2      <= ctrl_q2_i;
			next_funct        <= funct_i;
		end
	end

	assign pc_incr_o      = next_pc_incr;
	assign reg_rd_data1_o = next_reg_rd_data1;
	assign reg_rd_data2_o = next_reg_rd_data2;
	assign reg_wr_port_o  = next_reg_wr_port;
	assign imm_se_o       = next_imm_se;
	assign ctrl_q2_o      = next_ctrl_q2;
	assign funct_o        = next_funct;

endmodule