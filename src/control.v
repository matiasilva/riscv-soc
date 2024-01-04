/*
generates the necessary control signals for muxes

[alu_src] sign-extended immediate OR rs2 field of instruction
[is_regwrite] enable writeback to regfile
[]
*/

module control (
	input clk,
	input rst_n,
	input [6:0] opcode_i,
	output [1:0] aluop_o,
	output is_memread_o,
	output is_memwrite_o,
	output is_regwrite_o,
	output is_mem_to_reg_o,
	output regwrite_src_o,
	output is_branch_o,
	output alu_src_o,
);

	reg [1:0] aluop;
	reg is_memread;
	reg is_memwrite;
	reg is_regwrite;
	reg is_mem_to_reg;
	reg reg_dest;
	reg is_branch;
	reg alu_src;

	always @(*) begin :
		case (opcode_i)
			7'b0110011 : begin
				// R-type
				is_memread    = 1'b0;
				is_memwrite   = 1'b0;
				is_regwrite   = 1'b1;
				is_mem_to_reg = 1'b0;
				regwrite_src  = 1'b0;
				is_branch     = 1'b0;
				alu_src       = 1'b1;
				aluop         = 2'b10;
			end
			7'b0010011 : begin
				// I-type
				is_memread    = 1'b0;
				is_memwrite   = 1'b0;
				is_regwrite   = 1'b1;
				is_mem_to_reg = 1'b0;
				regwrite_src  = 1'b0;
				is_branch     = 1'b0;
				alu_src       = 1'b0;
				aluop         = 2'b10;
			end
			7'b0000011 : begin
				// load
			end
			7'b0100011 : begin
				// store
			end
		endcase
	end

	assign aluop_o       = aluop;
	assign is_memread_o  = is_memread;
	assign is_memwrite_o = is_memwrite;
	assign is_regwrite_o = is_regwrite;
	assign mem_to_reg_o  = mem_to_reg;
	assign reg_dest_o    = reg_dest;
	assign is_branch_o   = is_branch;
	assign alu_src_o     = alu_src;

endmodule