module EXMEM (
	input clk,
	input rst_n,
	input [31:0] pc_next_i,
	input [31:0] alu_out_i,
	input [31:0] rdata2_i,
	input [31:0] wr_addr_i,
	output [31:0] pc_next_o,
	output [31:0] alu_out_o,
	output [31:0] rdata2_o,
	output [31:0] wr_addr_o,
);

reg [31:0] next_pc_next;
reg [31:0] next_alu_out;
reg [31:0] next_rdata2;
reg [31:0] next_wr_addr;


always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		next_pc_next <= 0;
		next_alu_out <= 0;
		next_wr_addr <= 0;
		next_rdata2 <= 0;
	end else begin
		next_pc_next <= pc_incr_i;
		next_alu_out <= alu_out_i;
		next_rdata2  <= rdata2_i;
		next_wr_addr <= wr_addr_i;
	end
end

assign pc_next_o = next_pc_next;
assign alu_out_o = next_alu_out;
assign rdata2_o = next_rdata2;
assign wr_addr_o = next_wr_addr;

endmodule