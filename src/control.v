/*
generates the necessary control signals for muxes

[alusrc] select sign-extended immediate OR rs2 field of instruction
[reg_we] enable writeback to regfile
[is_mem_to_reg] select whether ALU result or memory read is written to regfile
*/


module control
	#(parameter CTRL_WIDTH = 16)
 (
	input [6:0] opcode_i,
	output [CTRL_WIDTH - 1:0] ctrl_o
);

 	localparam OP_RTYPE = 7'b0110011;
 	localparam OP_ITYPE = 7'b0010011;
 	localparam OP_LOAD  = 7'b0000011;
 	localparam OP_STORE = 7'b0100011;

	reg [1:0] aluop;
	reg mem_re;
	reg mem_we;
	reg reg_we;
	reg is_mem_to_reg;
	reg is_branch;
	reg alusrc;

	always @(*) begin
		case (opcode_i)
			OP_RTYPE : begin
				mem_re        = 1'b0;
				mem_we        = 1'b0;
				reg_we        = 1'b1;
				is_mem_to_reg = 1'b0;
				is_branch     = 1'b0;
				alusrc        = 1'b1;
				aluop         = 2'b10;
			end
			OP_ITYPE : begin
				mem_re        = 1'b0;
				mem_we        = 1'b0;
				reg_we        = 1'b1;
				is_mem_to_reg = 1'b0;
				is_branch     = 1'b0;
				alusrc        = 1'b0;
				aluop         = 2'b10;
			end
			OP_LOAD : begin
				mem_re        = 1'b1;
				mem_we        = 1'b0;
				reg_we        = 1'b1;
				is_mem_to_reg = 1'b1;
				is_branch     = 1'b0;
				alusrc        = 1'b0;
				aluop         = 2'b00;
			end
			OP_STORE : begin
				mem_re        = 1'b0;
				mem_we        = 1'b1;
				reg_we        = 1'b0;
				is_mem_to_reg = 1'b0; // DC
				is_branch     = 1'b0;
				alusrc        = 1'b0;
				aluop         = 2'b00;
			end
			default : begin
				mem_re        = 1'b0;
				mem_we        = 1'b0;
				reg_we        = 1'b0;
				is_mem_to_reg = 1'b0; // DC
				is_branch     = 1'b0;
				alusrc        = 1'b0;
				aluop         = 2'b00;
			end
		endcase
	end

	wire [2:0] q3_bits = {aluop, alusrc};
	wire [2:0] q4_bits = {is_branch, mem_re, mem_we};
	wire [1:0] q5_bits = {reg_we, is_mem_to_reg};
	assign ctrl_o = {8'b0, q3_bits, q4_bits, q5_bits};

endmodule