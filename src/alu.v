/*
[alucontrol]
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
	input         clk         ,
	input         rst_n       ,
	input  [31:0] a_i         ,
	input  [31:0] b_i         ,
	input  [ 3:0] alucontrol_i,
	output [31:0] out_o
);

	wire [31:0] diff = a_i - b_i;
	wire [4:0] shamt = b_i[4:0];

	reg [31:0] result;

	always @(*) begin
		case (op)
			4'b0000 : result = a_i + b_i;
			4'b1000 : result = diff;
			4'b0010 : begin
				if (a_i[31] ^ b_i[31]) begin
					result = a_i[31];
				end else begin
					result = diff[31];
				end
			end
			4'b0011 : result = a_i < b_i;
			4'b0111 : result = a_i & b_i;
			4'b0110 : result = a_i | b_i;
			4'b0100 : result = a_i ^ b_i;
			4'b0001 : result = a_i << shamt;
			4'b0101 : result = a_i >> shamt;
			4'b1101 : result = ($signed(a_i) >>> shamt);
		endcase
	end

	assign out = result;


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