module decoder (
	input clk,
	input rst_n,
	input [31:0] instr,
	output [3:0] alu_op
);

	wire [6:0] opcode = instr[6:0];

	// source and destination registers 
	wire [4:0] rs1 = instr[19:15];
	wire [4:0] rs2 = instr[24:20];
	wire [4:0] rd  = instr[11:7];

	wire [2:0] funct3 = instr[14:12];
  	wire [6:0] funct7 = instr[31:25];

  	wire [3:0] rtype_alu_op;

  	// R-type
  	always @(*) begin :
  		case (funct3)
  			3'b000: begin
  				// ADD, SUB
  				if (func7[5]) begin
  					// SUB
  				end else begin
  					// ADD
  				end
  			end
  			3'b001: begin
  				// SUB
  			end
  			3'b010: begin
  			end
  			3'b011: begin
  			end
  			3'b100: begin
  			end
  			3'b101: begin
  			end
  			3'b110: begin
  			end
  			3'b111: begin
  			end
  		endcase
  	end

	always @(posedge clk or negedge rst_n) begin :
		if(~rst_n) begin
			alu_op <= 4'b0;
		end else begin
			case (opcode)
				7'b0110011: begin
					// ALU operations on registers
					// R-type


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



endmodule