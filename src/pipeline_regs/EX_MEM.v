module EX_MEM (
	input clk,
	input rst_n,
	input [31:0] pc_incr_i,
	input [31:0] alu_out_i,
	input [31:0] rdata2_i,
	output [31:0] pc_incr_o,
	output [31:0] alu_out_o,
	output [31:0] rdata2_o,
);

reg [31:0] next_pc_incr;
reg [31:0] next_alu_out;
reg [31:0] next_rdata2;


always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		next_pc_incr <= 0;
		next_alu_out <= 0;
		next_rdata2 <= 0;
	end else begin
		next_pc_incr <= pc_incr_i;
		next_alu_out <= alu_out_i;
		next_rdata2  <= rdata2_i;
	end
end

assign pc_incr_o = next_pc_incr;
assign alu_out_o = next_alu_out;
assign rdata2_o = next_rdata2;

endmodule