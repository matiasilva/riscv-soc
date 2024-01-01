/*
	translates instructions into control signals
*/

module control (
	input clk,
	input rst_n,
	input [31:0] instr,
	output [3:0] alu_op
);

	wire [6:0] opcode = instr[6:0];

	// source and destination registers 


	wire [2:0] funct3 = instr[14:12];
  	wire [6:0] funct7 = instr[31:25];

  	wire [11:0] imm = instr[31:20];
   	wire [6:0] imm_upper = imm[11:5];
  	wire [4:0] imm_lower = imm[4:0];


  	wire [3:0] rtype_alu_op = {funct7[5], funct3};

  	reg [3:0] next_alu_op;

  	// I-type decode



	always @(posedge clk or negedge rst_n) begin :
		if(~rst_n) begin
			alu_op <= 4'b0;
		end else begin
			case (opcode)
				7'b0110011: begin
					// ALU operations on registers
					// R-type
					next_alu_op <= rtype_alu_op;
				end
				7'b0010011: begin
					// ALU operations on immediates
					// I-type
				end
				7'b0000011: begin
					// load
				end
				7'b0100011: begin
					// store
				end
			endcase
		end
	end

	assign alu_op = next_alu_op;


endmodule