/*
	The ISA defines 10 operations our ALU must perform:

	4'b0000 ADD
	4'b0001 SUB
	4'b0010 SLT
	4'b0011 SLTU
	4'b0100 AND
	4'b0101 OR
	4'b0110 XOR
	4'b0111 SLL
	4'b1000 SRL
	4'b1001 SRA


*/

module alu (
	input clk,
	input rst_n,
	input [31:0] a,
	input [31:0] b,
	input [3:0] op,
	output [31:0] out
);

	reg [31:0] result;

	wire [31:0] a_unsigned = 

	always @(*) begin :
		case (op)
			4'b0000: result = a + b;
			4'b0001: result = a - b;
			4'b0010: begin

			end
			4'b0011: result = a < b ? 1 : 0;
			4'b0100: result = a & b;
			4'b0101 result = a | b;
			4'b0110 result = a ^ b;
			4'b0111 SLL
			4'b1000 SRL
			4'b1001 SRA
		endcase
	end

	always @(posedge clk or negedge rst_n) begin 
		if(~rst_n) begin
			out <= 32'b0;
		end else begin
			out <= result;
		end
	end

endmodule