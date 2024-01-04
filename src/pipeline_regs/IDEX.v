module IDEX (
	input clk,
	input rst_n,
	input [31:0] pc_incr_i,
	input [31:0] rd_data1_i,
	input [31:0] rd_data2_i,
	input [31:0] wr_addr_i,
	input [31:0] imm_se_i,
	output [31:0] pc_incr_o,
	output [31:0] rd_data1_o,
	output [31:0] rd_data2_o,
	output [31:0] wr_addr_o,
	output [31:0] imm_se_o	
);

reg [31:0] next_pc_incr;
reg [31:0] next_rdata1;
reg [31:0] next_rdata2;
reg [31:0] next_wr_addr;
reg [31:0] next_imm_se;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		next_pc_incr <= 0;
		next_rdata1 <= 0;
		next_rdata2 <= 0;
		next_wr_addr <= 0;
		next_imm_se <= 0;
	end else begin
		next_pc_incr <= pc_incr_i;
		next_rdata1 <= rd_data1_i;
		next_rdata2 <= rd_data2_i;
		next_wr_addr <= wr_addr_i;
		next_imm_se <= imm_se_i;
	end
end

assign pc_incr_o = next_pc_incr;
assign rd_data1_o = next_rdata1;
assign rd_data2_o = next_rdata2;
assign wr_addr_o = next_wr_addr;
assign imm_se_o = next_imm_se;

endmodule