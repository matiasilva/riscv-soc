/*
	this module produces the required control signal for the ALU

	[aluop] is a 2-bit signal coming from the main control unit

	00 -> ADD (for lw, sw)
	10 -> hand over control to funct (essentially passthrough)
	11 -> not implemented
	01 -> SLTU (for beq)

	
	[funct] combines bit 5 of the funct7 field with all 3 bits of funct3
	TODO: can this be improved? we're wasting 6 out of 16 options

	[alucontrol_out] needs to be 4 bits wide to fit 10 operations
*/

module aluctrl (
	input [1:0] ctrl_aluop_i,
	input [3:0] funct_i,
	output [3:0] aluctrl_ctrl_o
);

	localparam ADD = 4'b0000;
	localparam SETLESSTHANUNSIGNED = 4'b0011;

	reg [2:0] control;

	always @(*) begin
		case (ctrl_aluop_i)
			2'b00: begin
				// SW/LW -> add
				control = ADD;
			end
			2'b01: begin
				control = SETLESSTHANUNSIGNED;
			end
			2'b10: begin
				control = funct_i;
			end
			2'b11: begin
				// unused
			end		
		endcase
	end

	assign aluctrl_ctrl_o = control;

endmodule