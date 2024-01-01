`include "memory.v"
//`include "decoder.v"
`include "alu.v"
`include "registers.v"

module core (
	input clk,    // Clock
	input rst_n  // Asynchronous reset active low
);

reg [31:0] pc;
wire [31:0] instr;
wire [3:0] alu_op;

wire [4:0] rs1 = instr[19:15];
wire [4:0] rs2 = instr[24:20];
wire [4:0] rd  = instr[11:7];

wire [4:0]

memory instrmem_u (
	.clk   (clk),
	.rst_n (rst_n),
	.pc   (pc),
	.instr(instr)
);

alu alu_u (
	.clk  (clk),
	.rst_n(rst_n),
	.a    (a),
);

regfile regfile_u (
	);

control control_u (
	);

alucontrol alucontrol_u (
	);

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		pc <= 0;
	end else begin
		pc <= pc + 4;
	end
end


endmodule