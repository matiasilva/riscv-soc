/*
generates the necessary control signals for muxes

[alu_src] select sign-extended immediate OR rs2 field of instruction
[reg_we] enable writeback to regfile
[is_mem_to_reg] select whether ALU result or memory read is written to regfile
*/

module control (
	input [6:0] opcode_i,
	output [1:0] ctrl_aluop_o,
	output ctrl_mem_re_o,
	output ctrl_mem_we_o,
	output ctrl_reg_we_o,
	output ctrl_is_mem_to_reg_o,
	output ctrl_is_branch_o,
	output ctrl_alusrc_o,
);

	reg [1:0] aluop;
	reg mem_re;
	reg mem_we;
	reg reg_we;
	reg is_mem_to_reg;
	reg is_branch;
	reg alu_src;

	always @(*) begin :
		case (opcode_i)
			7'b0110011 : begin
				// R-type
				mem_re    = 1'b0;
				mem_we   = 1'b0;
				reg_we   = 1'b1;
				is_mem_to_reg = 1'b0;
				is_branch     = 1'b0;
				alu_src       = 1'b1;
				aluop         = 2'b10;
			end
			7'b0010011 : begin
				// I-type
				mem_re    = 1'b0;
				mem_we   = 1'b0;
				reg_we   = 1'b1;
				is_mem_to_reg = 1'b0;
				is_branch     = 1'b0;
				alu_src       = 1'b0;
				aluop         = 2'b10;
			end
			7'b0000011 : begin
				// load
				mem_re    = 1'b1;
				mem_we   = 1'b0;
				reg_we   = 1'b1;
				is_mem_to_reg = 1'b1;
				is_branch     = 1'b0;
				alu_src       = 1'b0;
				aluop         = 2'b00;
			end
			7'b0100011 : begin
				// store
				mem_re    = 1'b0;
				mem_we   = 1'b1;
				reg_we   = 1'b0;
				is_mem_to_reg = 1'b0; // DC
				is_branch     = 1'b0;
				alu_src       = 1'b0;
				aluop         = 2'b00;
			end
		endcase
	end

	assign ctrl_aluop_o       = aluop;
	assign ctrl_mem_re_o  = mem_re;
	assign ctrl_mem_we_o = mem_we;
	assign ctrl_reg_we_o = reg_we;
	assign ctrl_mem_to_reg_o  = mem_to_reg;
	assign ctrl_is_branch_o   = is_branch;
	assign ctrl_alusrc_o     = alu_src;

endmodule