/*
generates the necessary control signals for muxes

[alusrc] select sign-extended immediate OR rs2 field of instruction
[reg_we] enable writeback to regfile
[is_mem_to_reg] select whether ALU result or memory read is written to regfile
*/

module control (
	input [6:0] opcode_i,
	output [CTRL_WIDTH - 1:0] ctrl_q2_o,
);

	reg [1:0] aluop;
	reg mem_re;
	reg mem_we;
	reg reg_we;
	reg is_mem_to_reg;
	reg is_branch;
	reg alusrc;

	always @(*) begin :
		case (opcode_i)
			7'b0110011 : begin
				// R-type
				mem_re    = 1'b0;
				mem_we   = 1'b0;
				reg_we   = 1'b1;
				is_mem_to_reg = 1'b0;
				is_branch     = 1'b0;
				alusrc       = 1'b1;
				aluop         = 2'b10;
			end
			7'b0010011 : begin
				// I-type
				mem_re    = 1'b0;
				mem_we   = 1'b0;
				reg_we   = 1'b1;
				is_mem_to_reg = 1'b0;
				is_branch     = 1'b0;
				alusrc       = 1'b0;
				aluop         = 2'b10;
			end
			7'b0000011 : begin
				// load
				mem_re    = 1'b1;
				mem_we   = 1'b0;
				reg_we   = 1'b1;
				is_mem_to_reg = 1'b1;
				is_branch     = 1'b0;
				alusrc       = 1'b0;
				aluop         = 2'b00;
			end
			7'b0100011 : begin
				// store
				mem_re    = 1'b0;
				mem_we   = 1'b1;
				reg_we   = 1'b0;
				is_mem_to_reg = 1'b0; // DC
				is_branch     = 1'b0;
				alusrc       = 1'b0;
				aluop         = 2'b00;
			end
		endcase
	end

	wire [2:0] q1_a = {aluop, alusrc};
	wire [2:0] q1_b = {is_branch, mem_re, mem_we};
	wire [1:0] q1_c = {reg_we, is_mem_to_reg}
	assign ctrl_q2_o = {8'b0, q1_a, q1_b, q1_c};

endmodule