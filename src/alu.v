/*
The ISA defines 10 operations our ALU must perform:

4'b0000 ADD
4'b1000 SUB
4'b0010 SLT
4'b0011 SLTU
4'b0111 AND
4'b0110 OR
4'b0100 XOR
4'b0001 SLL
4'b0101 SRL
4'b1101 SRA

*/

module alu (
	input         clk  ,
	input         rst_n,
	input  [31:0] a    ,
	input  [31:0] b    ,
	input  [ 3:0] op   ,
	output reg [31:0] out
);

	wire [31:0] diff = a - b;
	wire [4:0] shamt = b[4:0];

	always @(*) begin
			case (op)
				4'b0000 : out = a + b;
				4'b1000 : out = diff;
				4'b0010 : begin
					if (a[31] ^ b[31]) begin
						out = a[31];
					end else begin
						out = diff[31];
					end
				end
				4'b0011 : out = a < b;
				4'b0111 : out = a & b;
				4'b0110 : out = a | b;
				4'b0100 : out = a ^ b;
				4'b0001 : out = a << shamt;
				4'b0101 : out = a >> shamt;
				4'b1101 : out = ($signed(a) >>> shamt);
			endcase
		end


/*
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			out <= 32'b0;
		end else begin
			out <= result;
		end
	end
*/


endmodule