`include "memory.v"
`include "alu.v"
`include "registers.v"
`include "instrmem.v"
`include "control.v"
`include "aluctrl.v"

`include "pipeline_regs/IFID.v"
`include "pipeline_regs/IDEX.v"
`include "pipeline_regs/EXMEM.v"
`include "pipeline_regs/MEMWB.v"

`define CTRL_WIDTH 16
`define CTRL_ALUOP1 7
`define CTRL_ALUOP0 6
`define CTRL_ALUSRC 5
`define CTRL_IS_BRANCH 4
`define CTRL_MEM_RE 3
`define CTRL_MEM_WE 2
`define CTRL_REG_WE 1
`define CTRL_IS_MEM_TO_REG 0

module core (
	input clk,
	input rst_n
);

/*
	instruction fetch pipeline stage
*/

	reg  [31:0] pc                  ;
	reg  [31:0] pc_incr             ;
	wire [31:0] instr   = instr_q2;

	wire [31:0] pc_incr_q2;
	wire [31:0] instr_q1  ;
	wire [31:0] instr_q2  ;

/*
	instruction decode and register file pipeline stage
*/
	// instruction decode
	wire [ 4:0] rs1       = instr[19:15];
	wire [ 4:0] rs2       = instr[24:20];
	wire [ 4:0] rd        = instr[11:7] ;
	wire [ 2:0] funct3    = instr[14:12];
	wire [ 6:0] funct7    = instr[31:25];
	wire [ 6:0] opcode    = instr[6:0]  ;
	wire [11:0] imm       = instr[31:20];
	wire [ 6:0] imm_upper = instr[31:25];
	wire [ 4:0] imm_lower = instr[11:7] ;

	// register file
	wire [31:0] reg_rd_data1_q2;
	wire [31:0] reg_rd_data2_q2;
	wire [ 4:0] reg_rd_1    = rs1;
	wire [ 4:0] reg_rd_2    = rs2;
	wire [ 4:0] reg_wr_addr    = rd;
	wire [31:0] reg_wr_data = ctrl_q4_o[CTRL_IS_MEM_TO_REG] ? mem_rdata_q5 : alu_out_q5;

/*
	ALU and instruction execute pipeline stage
*/
	// ALU
	reg [31:0] imm_se_q2;
	wire [31:0] alu_in1 = reg_rd_data1_q3;
	wire [31:0] alu_in2 = ctrl_q3[CTRL_ALUSRC] ? reg_rd_data2 : imm_se_q3;
	wire [31:0] alu_out_q3;

	// ALU control
	wire [3:0] aluctrl_ctrl;
	wire [3:0] funct_q2 = {funct7[5], funct3};
	wire [3:0] funct_q3;

	// pipeline wires
	wire [31:0] imm_se_q3;
	wire [31:0] pc_incr_q3;
	wire [31:0] reg_rd_data1_q3;
	wire [31:0] reg_rd_data2_q3;
	wire [31:0] reg_wr_addr_q3;

	// helpers
	wire [1:0] ctrl_aluop = {ctrl_q3[CTRL_ALUOP1], ctrl_q3[CTRL_ALUOP0]};


/*
	memory access pipeline stage
*/

	wire [31:0] mem_rdata_q4;

	// pipeline wires 
	wire [31:0] pc_next_q3 = (imm_se_q3 << 2) | pc_incr_q3;
	wire [31:0] pc_next_q4;
	wire [31:0] reg_wr_addr_q4;
	wire [31:0] reg_rd_data2_q4;
	wire [31:0] alu_out_q4;


/*
	writeback pipeline stage
*/

	wire [31:0] alu_out_q5;
	wire [31:0] mem_rdata_q5;


/*
	main control unit
*/
// TODO: is it more efficient to forward specific sub signals?
	wire [CTRL_WIDTH-1:0] ctrl_q2;
	wire [CTRL_WIDTH-1:0] ctrl_q3;
	wire [CTRL_WIDTH-1:0] ctrl_q4;
	wire [CTRL_WIDTH-1:0] ctrl_q4_o;


	instrmem instrmem_u (
		.clk    (clk       ),
		.rst_n  (rst_n     ),
		.pc_i   (pc        ),
		.instr_o(instr_q1)
	);

	alu alu_u (
		.clk           (clk         ),
		.rst_n         (rst_n       ),
		.alu_a_i       (alu_in1     ),
		.alu_b_i       (alu_in2     ),
		.aluctrl_ctrl_i(aluctrl_ctrl),
		.alu_out_o     (alu_out_q3)
	);

	regfile regfile_u (
		.clk           (clk              ),
		.rst_n         (rst_n            ),
		.reg_rd_r1_i   (reg_rd_1         ),
		.reg_rd_r2_i   (reg_rd_2         ),
		.reg_rd_data1_o(reg_rd_data1_q2),
		.reg_rd_data2_o(reg_rd_data2_q2),
		.reg_wr_addr_i (reg_wr_addr      ),
		.reg_wr_data_i (reg_wr_data      ),
		.ctrl_reg_we_i (ctrl_q4_o[CTRL_REG_WE])
	);

	control control_u (
		.opcode_i   (opcode   ),
		.ctrl_q2_o(ctrl_q2)
	);

	aluctrl alucontrol_u (
		.ctrl_aluop_i  (ctrl_aluop    ),
		.funct_i       (funct_q3    ),
		.aluctrl_ctrl_o(aluctrl_ctrl_o)
	);

	memory memory_u (
		.clk          (clk              ),
		.rst_n        (rst_n            ),
		.ctrl_mem_re_i(ctrl_q4[CTRL_MEM_RE]      ),
		.ctrl_mem_we_i(ctrl_q4[CTRL_MEM_WE]      ),
		.addr_i       (alu_out_q4     ),
		.wdata_i      (reg_rd_data2_q4),
		.rdata_o      (mem_rdata_q4   )
	);


/*
	pipeline registers
*/

	IFID if_id_pregs (
		.clk      (clk         ),
		.rst_n    (rst_n       ),
		.pc_incr_i(pc_incr     ),
		.instr_i  (instr_q1  ),
		.instr_o  (instr_q2  ),
		.pc_incr_o(pc_incr_q2)
	);

	IDEX id_ex_pregs (
		.clk       (clk              ),
		.rst_n     (rst_n            ),
		.imm_se_i  (imm_se_q2      ),
		.imm_se_o  (imm_se_q3      ),
		.pc_incr_i (pc_incr_q2     ),
		.pc_incr_o (pc_incr_q3     ),
		.rd_data1_i(reg_rd_data1_q2),
		.rd_data1_o(reg_rd_data1_q3),
		.rd_data2_i(reg_rd_data2_q2),
		.rd_data2_o(reg_rd_data2_q3),
		.wr_addr_i (reg_wr_addr      ),
		.wr_addr_o (reg_wr_addr_q3 ),
		.ctrl_q2 (ctrl_q2        ),
		.ctrl_q2_o (ctrl_q3        ),
		.funct_i   (funct_q2       ),
		.funct_o   (funct_q3       )
	);

	EXMEM ex_mem_pregs (
		.clk      (clk              ),
		.rst_n    (rst_n            ),
		.pc_next_i(pc_next_q3     ),
		.pc_next_o(pc_next_q4     ),
		.wr_addr_i(reg_wr_addr_q3 ),
		.wr_addr_o(reg_wr_addr_q4 ),
		.rdata2_i (reg_rd_data2_q3),
		.rdata2_o (reg_rd_data2_q4),
		.alu_out_i(alu_out_q3     ),
		.alu_out_o(alu_out_q4     )
		.ctrl_q3(ctrl_q3),
		.ctrl_q3_o(ctrl_q4),
	);

	MEMWB mem_wb_pregs (
		.clk        (clk           ),
		.rst_n      (rst_n         ),
		.alu_out_i  (alu_out_q4  ),
		.alu_out_o  (alu_out_q5  ),
		.mem_rdata_i(mem_rdata_q4),
		.mem_rdata_o(mem_rdata_q5)
		.ctrl_q4  (ctrl_q4),
		.ctrl_q4_o  (ctrl_q4_o),
	);

/*
	sign extension
	note to self: SRLI, SLLI, SRAI use a specialization of the I-format
	but this does not affect our logic as a sign extension
	does not affect the lower 5 bits of the immediate
	which is what we actually care about
*/
	always @(*) begin
		imm_se_q2 = imm;
	end

	always @(*) begin
		pc = is_branch ? pc_next_q4: pc_incr;
	end

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			pc_incr <= 0;
		end else begin
			pc_incr <= pc_incr + 4;
		end
	end

endmodule