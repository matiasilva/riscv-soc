`include "memory.v"
`include "alu.v"
`include "registers.v"
`include "instrmem.v"
`include "control.v"
`include "aluctrl.v"



`include "pipeline_regs/IF_ID.v"
`include "pipeline_regs/ID_EX.v"
`include "pipeline_regs/EX_MEM.v"
`include "pipeline_regs/MEM_WB.v"

module core (
	input clk,
	input rst_n
);

reg [31:0] pc;
reg [31:0] pc_incr;
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
wire [31:0] reg_rd_data1_q2_i;
wire [31:0] reg_rd_data2_q2_i;
wire [ 4:0] reg_rd_1    = rs1;
wire [ 4:0] reg_rd_2    = rs2;
wire [ 4:0] reg_wr_addr    = rd;
wire [31:0] reg_wr_data = is_mem_to_reg ? mem_rdata_q4_o : alu_out_q4_o;

// main control unit signals
wire [1:0] ctrl_aluop;
wire ctrl_mem_re;
wire ctrl_mem_we;
wire ctrl_reg_we;
wire ctrl_is_mem_to_reg;
wire ctrl_is_branch;
wire ctrl_alusrc;

// alu
reg [31:0] imm_se_q2_i;
wire [31:0] alu_in1 = reg_rd_data1_q2_o;
wire [31:0] alu_in2 = alu_src ? reg_rd_data2 : imm_se_q2_o;
wire [31:0] alu_out_q3_i;

// alu control unit
wire [3:0] aluctrl_ctrl;
wire [3:0] funct = {funct7[5], funct3};

// memory
wire [31:0] mem_rdata_q4_i;

instrmem instrmem_u (
	.clk  (clk  ),
	.rst_n(rst_n),
	.pc_i   (pc   ),
	.instr_o(instr_q1_i)
);

alu alu_u (
	.clk         (clk       ),
	.rst_n       (rst_n     ),
	.alu_a_i         (alu_in1   ),
	.alu_b_i         (alu_in2   ),
	.aluctrl_ctrl_i(aluctrl_ctrl),
	.alu_out_o       (alu_out_q3_i   )
);

regfile regfile_u (
	.clk           (clk              ),
	.rst_n         (rst_n            ),
	.reg_rd_r1_i   (reg_rd_1         ),
	.reg_rd_r2_i   (reg_rd_2         ),
	.reg_rd_data1_o(reg_rd_data1_q2_i),
	.reg_rd_data2_o(reg_rd_data12q2_i),
	.reg_wr_addr_i (reg_wr_addr      ),
	.reg_wr_data_i (reg_wr_data      ),
	.ctrl_reg_we_i (ctrl_reg_we      )
);

control control_u (
	.opcode_i            (opcode            ),
	.aluop_o             (ctrl_aluop        ),
	.ctrl_mem_re_o       (ctrl_mem_re       ),
	.ctrl_mem_we_o       (ctrl_mem_we       ),
	.ctrl_reg_we_o       (ctrl_reg_we       ),
	.ctrl_is_mem_to_reg_o(ctrl_is_mem_to_reg),
	.ctrl_is_branch_o    (ctrl_is_branch    ),
	.ctrl_alusrc_o       (ctrl_alusrc       )
);

aluctrl alucontrol_u (
	.ctrl_aluop_i     (ctrl_aluop),
	.funct_i     (funct),
	.aluctrl_ctrl_o(aluctrl_ctrl_o),
);

memory memory_u (
	.clk          (clk              ),
	.rst_n        (rst_n            ),
	.ctrl_mem_re_i(ctrl_mem_re      ),
	.ctrl_mem_we_i(ctrl_mem_we      ),
	.addr_i       (alu_out_q3_o     ),
	.wdata_i      (reg_rd_data2_q3_o),
	.rdata_o      (mem_rdata_q4_i   )
);

// pipeline registers
wire [31:0] pc_incr_q1_o;
wire [31:0] instr_q1_i;
wire [31:0] instr_q1_o;
IF_ID if_id_pregs (
	.clk      (clk),
	.rst_n    (rst_n),
	.pc_incr_i(pc_incr),
	.instr_i  (instr_q1_i),
	.instr_o  (instr_q1_o),
	.pc_incr_o(pc_incr_q1_o),
);


wire [31:0] imm_se_q2_o;
wire [31:0] pc_incr_q2_o;
wire [31:0] reg_rd_data1_q2_o;
wire [31:0] reg_rd_data2_q2_o;
wire [31:0] reg_wr_addr_q2_o;
ID_EX id_ex_pregs (
	.clk       (clk              ),
	.rst_n     (rst_n            ),
	.imm_se_i  (imm_se_q2_i           ),
	.imm_se_o  (imm_se_q2_o      ),
	.pc_incr_i (pc_incr_q1_o     ),
	.pc_incr_o (pc_incr_q2_o     ),
	.rd_data1_i(reg_rd_data1_q2_i     ),
	.rd_data1_o(reg_rd_data1_q2_o),
	.rd_data2_i(reg_rd_data2_q2_i     ),
	.rd_data2_o(reg_rd_data2_q2_o),
	.wr_addr_i (reg_wr_addr      ),
	.wr_addr_o (reg_wr_addr_q2_o )
);

wire [31:0] pc_next_q3_i = (imm_se_q2_o << 2) | pc_incr_q2_o;
wire [31:0] pc_next_q3_o;
wire [31:0] reg_wr_addr_q3_o;
wire [31:0] reg_rd_data2_q3_o;
wire [31:0] alu_out_q3_o;
EX_MEM ex_mem_pregs (
	.clk      (clk),
	.rst_n    (rst_n),
	.pc_next_i(pc_next_q3_i),
	.pc_next_o(pc_next_q3_o),
	.wr_addr_i(reg_wr_addr_q2_o),
	.wr_addr_o(reg_wr_addr_q3_o),
	.rdata2_i (reg_rd_data2_q2_o),
	.rdata2_o (reg_rd_data2_q3_o),
	.alu_out_i(alu_out_q3_i),
	.alu_out_o(alu_out_q3_o),
);

wire [31:0] alu_out_q4_o;
wire [31:0] mem_rdata_q4_o;
MEM_WB mem_wb_pregs (
	.clk       (clk),
	.rst_n     (rst_n),
	.alu_out_i (alu_out_q3_o),
	.alu_out_o (alu_out_q4_o),
	.mem_rdata_i(mem_rdata_q4_i),
	.mem_rdata_o(mem_rdata_q4_o)
);

/*
sign extension
note to self: SRLI, SLLI, SRAI use a specialization of the I-format
but this does not affect our logic as a sign extension
does not affect the lower 5 bits of the immediate
which is what we actually care about
*/
always @(*) begin
	imm_se_q2_i = imm;
end

always @(*) begin
	pc = is_branch ? pc_next_q3_o: pc_incr;
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		pc_incr <= 0;
	end else begin
		pc_incr <= pc_incr + 4;
	end
end



endmodule