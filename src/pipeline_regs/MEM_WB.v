module MEM_WB (
	input clk,
	input rst_n,
	input [31:0] alu_out_i,
	input [31:0] rdatamem_i,
	output [31:0] alu_out_o,
	output [31:0] rdatamem_o,
);

reg [31:0] next_pc_incr;
reg [31:0] next_alu_out;
reg [31:0] next_rdatamem;


always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		next_alu_out <= 0;
		next_rdatamem <= 0;
	end else begin
		next_alu_out <= alu_out_i;
		next_rdatamem  <= rdatamem_i;
	end
end

assign alu_out_o = next_alu_out;
assign rdatamem_o = next_rdatamem;

endmodule