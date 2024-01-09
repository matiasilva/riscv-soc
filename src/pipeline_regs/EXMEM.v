module EXMEM (
	input clk,
	input rst_n,
	input [31:0] pc_next_i,
	input [31:0] alu_out_i,
	input [31:0] rdata2_i,
	input [31:0] wr_addr_i,
	input [CTRL_WIDTH -1 :0] ctrl_q3_i,
	output [31:0] pc_next_o,
	output [31:0] alu_out_o,
	output [31:0] rdata2_o,
	output [31:0] wr_addr_o,
	output [CTRL_WIDTH -1 :0] ctrl_q3_o,
);

reg [31:0] next_pc_next;
reg [31:0] next_alu_out;
reg [31:0] next_rdata2;
reg [31:0] next_wr_addr;
reg [CTRL_WIDTH -1:0] next_ctrl_q3;


always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		next_pc_next <= 0;
		next_alu_out <= 0;
		next_wr_addr <= 0;
		next_rdata2 <= 0;
		next_ctrl_q3 <= 0;
	end else begin
		next_pc_next <= pc_incr_i;
		next_alu_out <= alu_out_i;
		next_rdata2  <= rdata2_i;
		next_wr_addr <= wr_addr_i;
		next_ctrl_q3 <= ctrl_q3_i;
	end
end

assign pc_next_o = next_pc_next;
assign alu_out_o = next_alu_out;
assign rdata2_o = next_rdata2;
assign wr_addr_o = next_wr_addr;
assign ctrl_q3_o = next_ctrl_q3;

endmodule