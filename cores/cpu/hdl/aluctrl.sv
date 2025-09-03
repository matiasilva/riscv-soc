/*
	this module produces the required ctrl signal for the ALU

	[aluop] is a 2-bit signal coming from the main ctrl unit

	00 -> ADD (for lw, sw)
	10 -> hand over ctrl to funct (essentially passthrough)
	11 -> not implemented
	01 -> SLTU (for beq)

	
	[funct] combines bit 5 of the funct7 field with all 3 bits of funct3
	TODO: can this be improved? we're wasting 6 out of 16 options

	[aluctrl_out] needs to be 4 bits wide to fit 10 operations
*/

module aluctrl (
    input  [1:0] i_ctrl_aluop,
    input  [3:0] i_funct,
    output [3:0] o_aluctrl_ctrl
);

  localparam ALUOP_ADD   = 2'b00;
  localparam ALUOP_FUNCT = 2'b10;
  localparam ALUOP_SLTU  = 2'b01;

  localparam ADD = 4'b0000;
  localparam SETLESSTHANUNSIGNED = 4'b0011;

  reg [3:0] ctrl;

  always @(*) begin
    ctrl = 4'hx;
    case (i_ctrl_aluop)
      ALUOP_ADD: begin
        // SW/LW -> add
        ctrl = ADD;
      end
      ALUOP_SLTU: begin
        ctrl = SETLESSTHANUNSIGNED;
      end
      ALUOP_FUNCT: begin
        ctrl = i_funct;
      end
    endcase
  end

  assign o_aluctrl_ctrl = ctrl;

endmodule
