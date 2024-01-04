module ID_EX (
	input clk,
	input rst_n,
	input [31:0] pc_incr_i,
	input [31:0] rdata1_i,
	input [31:0] rdata2_i,
	input [31:0] signextended_imm_i,
	output [31:0] pc_incr_o,
	output [31:0] rdata1_o,
	output [31:0] rdata2_o,
	output [31:0] signextended_imm_o	
);

reg [31:0] next_pc_incr;
reg [31:0] next_rdata1;
reg [31:0] next_rdata2;
reg [31:0] next_signextended_imm;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		next_pc_incr <= 0;
		next_rdata1 <= 0;
		next_rdata2 <= 0;
		next_signextended_imm <= 0;
	end else begin
		next_pc_incr <= pc_incr_i;
		next_rdata1 <= rdata1_i;
		next_rdata2 <= rdata2_i;
		next_signextended_imm <= signextended_imm_i;
	end
end

assign pc_incr_o = next_pc_incr;
assign rdata1_o = next_rdata1;
assign rdata2_o = next_rdata2;
assign signextended_imm_o = next_signextended_imm;

endmodule