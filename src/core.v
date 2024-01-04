`include "memory.v"
//`include "decoder.v"
`include "alu.v"
`include "registers.v"

module core (
	input clk,
	input rst_n
);

reg [31:0] pc;
wire [31:0] instr;

// instruction field select
wire [4:0] rs1 = instr[19:15];
wire [4:0] rs2 = instr[24:20];
wire [4:0] rd  = instr[11:7] ;

wire [2:0] funct3 = instr[14:12];
wire [6:0] funct7 = instr[31:25];

wire [6:0] opcode = instr[6:0];

wire [11:0] imm = instr[31:20];
wire [6:0] imm_upper = instr[31:25];
wire [4:0] imm_lower = instr[11:7] ;

// register file
wire [31:0] rdata1;
wire [31:0] rdata2;
wire [ 4:0] rr1    = rs1;
wire [ 4:0] rr2    = rs2;
wire [ 4:0] wrr    = rd;
wire [31:0] wrdata = is_mem_to_reg ? rdatamem : alu_out;

// main control unit signals
wire [1:0] aluop;
wire is_memread;
wire is_memwrite;
wire is_regwrite;
wire is_mem_to_reg;
wire is_branch;
wire alu_src;

// alu
reg [31:0] signextended_imm;
wire [31:0] alu_in1 = rdata1;
wire [31:0] alu_in2 = alu_src ? rdata2 : signextended_imm;
wire [31:0] alu_out;

// alu control unit
wire [3:0] alucontrol;
wire [3:0] funct = {funct7[5], funct3};

// memory
wire [31:0] rdatamem;

instrmem instrmem_u (
	.clk  (clk  ),
	.rst_n(rst_n),
	.pc   (pc   ),
	.instr(instr)
);

alu alu_u (
	.clk         (clk       ),
	.rst_n       (rst_n     ),
	.a_i         (alu_in1   ),
	.b_i         (alu_in2   ),
	.alucontrol_i(alucontrol),
	.out_o       (alu_out   )
);

regfile regfile_u (
	.clk          (clk        ),
	.rst_n        (rst_n      ),
	.rr1_i        (rr1        ),
	.rr2_i        (rr2        ),
	.wrr_i        (wrr        ),
	.rdata1_o     (rdata1     ),
	.rdata2_o     (rdata2     ),
	.wrdata_i     (wrdata     ),
	.is_regwrite_i(is_regwrite)
);

control control_u (
	.opcode_i       (opcode       ),
	.aluop_o        (aluop        ),
	.is_memread_o   (is_memread   ),
	.is_memwrite_o  (is_memwrite  ),
	.is_regwrite_o  (is_regwrite  ),
	.is_mem_to_reg_o(is_mem_to_reg),
	.is_branch_o    (is_branch    ),
	.alu_src_o      (alu_src      )
);

aluctl alucontrol_u (
	.aluop_i     (aluop),
	.funct_i     (funct),
	.alucontrol_o(alucontrol),
);

memory memory_u (
	.clk          (clk),
	.rst_n        (rst_n),
	.is_memread_i (is_memread),
	.is_memwrite_i(is_memwrite),
	.addr_i       (alu_out),
	.wdata_i      (rs2),
	.rdata_o      (rdatamem),
);

/*
sign extension
note to self: SRLI, SLLI, SRAI use a specialization of the I-format
but this does not affect our logic as a sign extension
does not affect the lower 5 bits of the immediate
which is what we actually care about
*/
always @(*) begin
	signextended_imm = imm;
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		pc <= 0;
	end else begin
		pc <= pc + 4;
	end
end


endmodule