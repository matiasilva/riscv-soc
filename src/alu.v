/*
[ctrl]
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
	input         clk           ,
	input         rst_n         ,
	input  [31:0] alu_a_i       ,
	input  [31:0] alu_b_i       ,
	input  [ 3:0] aluctrl_ctrl_i,
	output [31:0] alu_out_o
);

	wire [31:0] diff = alu_a_i - alu_b_i;
	wire [4:0] shamt = alu_b_i[4:0];

	reg [31:0] result;

	always @(*) begin
		case (aluctrl_ctrl_i)
			4'b0000 : result = alu_a_i + alu_b_i;
			4'b1000 : result = diff;
			4'b0010 : begin
				if (alu_a_i[31] ^ alu_b_i[31]) begin
					result = alu_a_i[31];
				end else begin
					result = diff[31];
				end
			end
			4'b0011 : result = alu_a_i < alu_b_i;
			4'b0111 : result = alu_a_i & alu_b_i;
			4'b0110 : result = alu_a_i | alu_b_i;
			4'b0100 : result = alu_a_i ^ alu_b_i;
			4'b0001 : result = alu_a_i << shamt;
			4'b0101 : result = alu_a_i >> shamt;
			4'b1101 : result = ($signed(alu_a_i) >>> shamt);
		endcase
	end

	assign alu_out = result;


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