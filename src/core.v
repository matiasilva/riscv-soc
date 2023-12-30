`include "memory.v"

module core (
	input clk,    // Clock
	input rst_n  // Asynchronous reset active low
);

reg [31:0] pc;
wire [31:0] instr;

memory instr_mem (
	.clk   (clk),
	.rst_n (rst_n),
	.pc   (pc),
	.instr(instr)
	);

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		pc <= 0;
	end else begin
		pc <= pc + 4;
	end
end


endmodule