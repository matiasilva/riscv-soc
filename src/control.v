/*
	translates instructions into control signals
*/

module control (
	input clk,
	input rst_n,
	input [6:0] opcode,
	output [1:0] alu_op
);

  	reg [3:0] next_aluop;

	always @(posedge clk or negedge rst_n) begin :
		if(~rst_n) begin
			alu_op <= 4'b0;
		end else begin
			case (opcode)
				7'b0110011: begin
					// ALU operations on registers
					// R-type
					next_aluop <= rtype_alu_op;
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