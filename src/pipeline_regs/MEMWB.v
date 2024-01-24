
module MEMWB 	#(parameter CTRL_WIDTH = 16)
(
	input clk,
	input rst_n,
	input [31:0] alu_out_i,
	input [31:0] mem_rdata_i,
	input [CTRL_WIDTH-1:0] ctrl_q4_i,
	output [31:0] alu_out_o,
	output [31:0] mem_rdata_o,
	output [CTRL_WIDTH-1:0] ctrl_q4_o
);

reg [31:0] next_pc_incr;
reg [31:0] next_alu_out;
reg [31:0] next_mem_rdata;
reg [CTRL_WIDTH-1:0] next_ctrl_q4;


always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		next_alu_out <= 0;
		next_mem_rdata <= 0;
		next_ctrl_q4 <= 0;
	end else begin
		next_alu_out <= alu_out_i;
		next_mem_rdata  <= mem_rdata_i;
		next_ctrl_q4 <= ctrl_q4_i;
	end
end

assign alu_out_o = next_alu_out;
assign mem_rdata_o = next_mem_rdata;
assign ctrl_q4_o = next_ctrl_q4;

endmodule