`ifndef CPU_TYPES_VH
`define CPU_TYPES_VH

//------------------------------------------------------------------------------
// RV32I opcodes
//------------------------------------------------------------------------------
typedef enum logic [6:0] {
  OP_LOAD   = 7'b0000011,
  OP_ITYPE  = 7'b0010011,
  OP_STORE  = 7'b0100011,
  OP_RTYPE  = 7'b0110011,
  OP_BRANCH = 7'b1100011,
  OP_JALR   = 7'b1100111,
  OP_JAL    = 7'b1101111
} opcode_t;

//------------------------------------------------------------------------------
// Instruction decode
//------------------------------------------------------------------------------
typedef struct packed {
  logic [24:0] upper;
  opcode_t     opcode;
} common_fields_t;

// R-type (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
typedef struct packed {
  logic [6:0] funct7;
  logic [4:0] rs2;
  logic [4:0] rs1;
  logic [2:0] funct3;
  logic [4:0] rd;
  logic [6:0] opcode;
} r_type_t;

// I-type (ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, LB, LH, LW, LBU, LHU, JALR)
typedef struct packed {
  logic [11:0] imm;
  logic [4:0]  rs1;
  logic [2:0]  funct3;
  logic [4:0]  rd;
  logic [6:0]  opcode;
} i_type_t;

// S-type (SB, SH, SW)
typedef struct packed {
  logic [6:0] imm_11_5;
  logic [4:0] rs2;
  logic [4:0] rs1;
  logic [2:0] funct3;
  logic [4:0] imm_4_0;
  logic [6:0] opcode;
} s_type_t;

// B-type (BEQ, BNE, BLT, BGE, BLTU, BGEU)
typedef struct packed {
  logic       imm_12;
  logic [5:0] imm_10_5;
  logic [4:0] rs2;
  logic [4:0] rs1;
  logic [2:0] funct3;
  logic [3:0] imm_4_1;
  logic       imm_11;
  logic [6:0] opcode;
} b_type_t;

// U-type (LUI, AUIPC)
typedef struct packed {
  logic [19:0] imm;
  logic [4:0]  rd;
  logic [6:0]  opcode;
} u_type_t;

// J-type (JAL)
typedef struct packed {
  logic       imm_20;
  logic [9:0] imm_10_1;
  logic       imm_11;
  logic [7:0] imm_19_12;
  logic [4:0] rd;
  logic [6:0] opcode;
} j_type_t;

typedef union packed {
  logic [31:0] raw;
  common_fields_t common;
  r_type_t r_type;
  i_type_t i_type;
  s_type_t s_type;
  b_type_t b_type;
  u_type_t u_type;
  j_type_t j_type;
} insn_t;

//------------------------------------------------------------------------------
// Instruction decode utilities
//------------------------------------------------------------------------------
function static logic [31:0] get_i_imm(insn_t insn);
  return {{20{insn.i_type.imm[11]}}, insn.i_type.imm};
endfunction

function static logic [31:0] get_s_imm(insn_t insn);
  return {{20{insn.s_type.imm_11_5[6]}}, insn.s_type.imm_11_5, insn.s_type.imm_4_0};
endfunction

function static logic [31:0] get_b_imm(insn_t insn);
  return {
    {19{insn.b_type.imm_12}},
    insn.b_type.imm_12,
    insn.b_type.imm_11,
    insn.b_type.imm_10_5,
    insn.b_type.imm_4_1,
    1'b0
  };
endfunction

function static logic [31:0] get_u_imm(insn_t insn);
  return {insn.u_type.imm, 12'b0};
endfunction

function static logic [31:0] get_j_imm(insn_t insn);
  return {
    {11{insn.j_type.imm_20}},
    insn.j_type.imm_20,
    insn.j_type.imm_19_12,
    insn.j_type.imm_11,
    insn.j_type.imm_10_1,
    1'b0
  };
endfunction

//------------------------------------------------------------------------------
// ALU
//------------------------------------------------------------------------------
typedef enum logic [1:0] {
  ALUOP_ADD     = 2'b00,
  ALUOP_SLTU    = 2'b01,
  ALUOP_FUNCT   = 2'b10,
  ALUOP_INVALID = 2'b11
} alu_ctrl_t;

typedef enum logic [3:0] {
  OP_ADD     = 4'b0000,
  OP_SLL     = 4'b0001,
  OP_SLT     = 4'b0010,
  OP_SLTU    = 4'b0011,
  OP_XOR     = 4'b0100,
  OP_SRL     = 4'b0101,
  OP_OR      = 4'b0110,
  OP_AND     = 4'b0111,
  OP_SUB     = 4'b1000,
  OP_SRA     = 4'b1101,
  OP_INVALID = 4'b1111
} alu_op_t;

typedef enum logic {
  ALUSRC_IMM = 1'b0,
  ALUSRC_REG = 1'b1
} alu_src_t;

//------------------------------------------------------------------------------
// Control unit
//
// Optimization: divide control unit data by pipeline stage
//------------------------------------------------------------------------------
typedef struct packed {logic is_jal;} cpu_ctrl_p2_t;

typedef struct packed {
  alu_ctrl_t alu_ctrl;
  alu_src_t  alu_src;
} cpu_ctrl_p3_t;

typedef struct packed {
  logic is_branch;
  logic mem_re;
  logic mem_we;
} cpu_ctrl_p4_t;

typedef struct packed {
  logic reg_wr_en;
  logic is_mem_to_reg;
} cpu_ctrl_p5_t;

typedef struct packed {
  cpu_ctrl_p2_t p2;
  cpu_ctrl_p3_t p3;
  cpu_ctrl_p4_t p4;
  cpu_ctrl_p5_t p5;
} cpu_ctrl_t;

//------------------------------------------------------------------------------
// Pipeline registers
//------------------------------------------------------------------------------
typedef struct packed {
  insn_t insn;
  logic [31:0] pc;
  logic [31:0] pc_incr;
} p1p2_t;

typedef struct packed {
  logic [31:0] pc;
  logic [31:0] pc_incr;
  logic [31:0] reg_rd_data1;
  logic [31:0] reg_rd_data2;
  logic [4:0]  reg_wr_port;
  cpu_ctrl_t   ctrl;
  insn_t       insn;
} p2p3_t;

typedef struct packed {
  logic [31:0] pc_next;
  logic [31:0] alu_out;
  logic [31:0] reg_rd_data2;
  logic [4:0]  reg_wr_port;
  cpu_ctrl_t   ctrl;
  insn_t       insn;
} p3p4_t;

typedef struct packed {
  logic [31:0] alu_out;
  logic [31:0] mem_rdata;
  logic [4:0]  reg_wr_port;
  cpu_ctrl_t   ctrl;
  insn_t       insn;
} p4p5_t;

`endif  // CPU_TYPES_VH
