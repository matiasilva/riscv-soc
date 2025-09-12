`ifndef CPU_TYPES_VH
`define CPU_TYPES_VH

typedef struct packed {
  logic [31:0] instruction;
  logic [4:0] rs1, rs2, rd;
  logic [6:0] opcode;
} instruction_t;

typedef enum logic [6:0] {
  OP_RTYPE  = 7'b0110011,
  OP_ITYPE  = 7'b0010011,
  OP_LOAD   = 7'b0000011,
  OP_STORE  = 7'b0100011,
  OP_JAL    = 7'b1101111,
  OP_JALR   = 7'b1100111,
  OP_BRANCH = 7'b1100011
} opcode_t;

typedef enum logic [1:0] {
  ALUOP_ADD   = 2'b00,
  ALUOP_SLTU  = 2'b01,
  ALUOP_FUNCT = 2'b10
} aluctrl_t;

typedef enum logic [3:0] {
  OP_ADD  = 4'b0000,
  OP_SUB  = 4'b1000,
  OP_SLT  = 4'b0010,
  OP_SLTU = 4'b0011,
  OP_AND  = 4'b0111,
  OP_OR   = 4'b0110,
  OP_XOR  = 4'b0100,
  OP_SLL  = 4'b0001,
  OP_SRL  = 4'b0101,
  OP_SRA  = 4'b1101
} aluop_t;

typedef enum logic {
  ALUSRC_IMM = 1'b0,
  ALUSRC_REG = 1'b1
} alusrc_t;

typedef struct packed {
  logic       q2_bits;  // is_jal
  logic [2:0] q3_bits;  // {aluop, alusrc}
  logic [2:0] q4_bits;  // {is_branch, mem_re, mem_we}
  logic [1:0] q5_bits;  // {reg_wr_en, is_mem_to_reg}
} cpu_ctrl_t;

`endif  // CPU_TYPES_VH
