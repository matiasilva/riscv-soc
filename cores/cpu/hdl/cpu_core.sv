// MIT License
//
// Copyright (c) 2025 Matias Wang Silva
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Module  : cpu_core
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Top-level wrapper for a 5-stage RISC-V pipeline processor
//   Pipeline stages:
//     P1: Instruction fetch
//     P2: Instruction decode / register file read
//     P3: Execute / ALU operations
//     P4: Memory access
//     P5: Write back
//
// Parameters:
//   HAZARD_TECHNIQUE - Hazard handling method (0=STALL, 1=FORWARD, 2=HYBRID, 3=AGGRESSIVE)
//   ENABLE_LOAD_USE_FORWARDING - Enable forwarding for load-use hazards

`include "cpu_types.vh"

module cpu_core #(
    parameter int HAZARD_TECHNIQUE           = 0,
    parameter int ENABLE_LOAD_USE_FORWARDING = 1
) (
    input i_clk,
    input i_rst_n
);

  //------------------------------------------------------------------------------
  // Pipeline registers
  //------------------------------------------------------------------------------
  p1p2_t p1p2, p1p2_q;
  p2p3_t p2p3, p2p3_q;
  p3p4_t p3p4, p3p4_q;
  p4p5_t p4p5, p4p5_q;

  //------------------------------------------------------------------------------
  // Instruction pipeline
  //------------------------------------------------------------------------------

  insn_t p2_insn, p3_insn;

  logic [31:0] p2_pc_next;  // JAL target address

  /* p2 out, p3 in */
  assign p3_insn = p2p3_q.insn;

  logic    [31:0] p3_imm_se;

  /* p3 out, p4 in */
  logic    [31:0] p3_pc_next;  // branch target address


  /* register file  */
  logic    [31:0] p4_reg_wr_data;

  /* alu & ctrl */
  logic    [31:0] alu_in1;
  logic    [31:0] alu_in2;
  alu_op_t        alu_ctrl;
  logic    [31:0] alu_in2_pre;
  logic    [31:0] p3_alu_out;

  /* data memory */
  logic    [31:0] mem_wdata;
  logic    [31:0] mem_rdata;
  logic    [31:0] mem_wdata_forwarded;

  /* pipeline control signals */
  logic stall_if, stall_id, stall_ex;
  logic flush_id, flush_ex;
  logic        enable_forwarding;

  logic [31:0] pc;
  logic [31:0] pc_plus_4_next;
  logic [31:0] pc_plus_4_q;
  logic        p2_pc_jal;

  /* forwarding unit */
  logic [31:0] alu_in1_forwarded;
  logic [31:0] alu_in2_forwarded;



  //------------------------------------------------------------------------------
  // Program counter
  //------------------------------------------------------------------------------

  always_comb begin
    pc = pc_plus_4_q;
    if (p2p3.ctrl.p2.is_jal) begin
      pc = p2_pc_next;
    end else if (p3p4_q.ctrl.p4.is_branch) begin
      pc = p3p4_q.pc_next;
    end
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      pc_plus_4_q <= '0;
    end else begin
      pc_plus_4_q <= pc_plus_4_next;
    end
  end

  assign pc_plus_4_next = pc + 4;

  insnmem #(
      .SIZE(4096)
  ) insnmem_u (
      .i_clk           (i_clk),
      .i_rst_n         (i_rst_n),
      .i_pc            (pc),
      .o_insn          (p2_insn),
      .o_imem_exception(  /* unused */)
  );

  assign p1p2 = '{pc: pc, pc_plus_4: pc_plus_4_q};

  p1p2 p1p2_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_p1p2 (p1p2),
      .o_p1p2 (p1p2_q)
  );

  //------------------------------------------------------------------------------
  // Instruction decode (p2)
  //------------------------------------------------------------------------------

  regfile regfile_u (
      .i_clk     (i_clk),
      .i_rst_n   (i_rst_n),
      .i_rd_addr1(p2_insn.r_type.rs1),
      .i_rd_addr2(p2_insn.r_type.rs2),
      .o_rd_data1(p2p3.reg_rd_data1),
      .o_rd_data2(p2p3.reg_rd_data2),
      .i_wr_addr (p4p5_q.insn.r_type.rd),
      .i_wr_data (p4p5_q.reg_wr_data),
      .i_wr_en   (p4p5_q.ctrl.p5.reg_wr_en)
  );

  control control_u (
      .i_opcode(p2_insn.common.opcode),
      .o_ctrl  (p2p3.ctrl)
  );

  always_comb begin
    p2p3.pc        = p1p2_q.pc;
    p2p3.pc_plus_4 = p1p2_q.pc_plus_4;
    p2p3.insn      = p2_insn;
  end

  p2p3 p2p3_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_p2p3 (p2p3),
      .o_p2p3 (p2p3_q)
  );

  //------------------------------------------------------------------------------
  // Execute / ALU (p3)
  //------------------------------------------------------------------------------

  always_comb begin : sign_extend_immediate
    case (p2p3_q.insn.common.opcode)
      OP_ITYPE, OP_LOAD, OP_JALR: p3_imm_se = get_i_imm(p3_insn);
      OP_STORE:                   p3_imm_se = get_s_imm(p3_insn);
      OP_BRANCH:                  p3_imm_se = get_b_imm(p3_insn);
      OP_JAL:                     p3_imm_se = get_j_imm(p3_insn);
      default:                    p3_imm_se = get_i_imm(p3_insn);
    endcase
  end

  aluctrl alucontrol_u (
      .i_aluop   (p2p3_q.ctrl.p3.alu_ctrl),
      .i_funct3  (p2p3_q.insn.r_type.funct3),
      .i_funct7_5(p2p3_q.insn.r_type.funct7[5]),
      .o_alu_ctrl(alu_ctrl)
  );

  alu alu_u (
      .i_alu_a        (alu_in1),
      .i_alu_b        (alu_in2),
      .i_alu_ctrl     (alu_ctrl),
      .o_alu_out      (p3_alu_out),
      .o_alu_exception(  /* unused */)
  );

  always_comb begin
    p3p4.pc_next      = p3_pc_next;
    p3p4.reg_rd_data2 = p2p3_q.reg_rd_data2;
    p3p4.ctrl         = p2p3_q.ctrl;
    p3p4.insn         = p2p3_q.insn;
  end

  p3p4 p3p4_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_p3p4 (p3p4),
      .o_p3p4 (p3p4_q)
  );

  //------------------------------------------------------------------------------
  // Memory access (p4)
  //------------------------------------------------------------------------------

  memory #(
      .PRELOAD(1),
      .PRELOAD_FILE("sim/dmem.hex")
  ) memory_u (
      .i_rst_n         (i_rst_n),
      .i_clk           (i_clk),
      .i_ctrl_mem_rd_en(p3p4_q.ctrl.p4.mem_rd_en),
      .i_ctrl_mem_wr_en(p3p4_q.ctrl.p4.mem_wr_en),
      .i_mem_addr      (p3_alu_out),
      .i_mem_wdata     (mem_wdata),
      .o_mem_rdata     (mem_rdata)
  );

  always_comb begin
    p4p5.reg_wr_data = p4_reg_wr_data;
    p4p5.ctrl        = p3p4_q.ctrl;
    p4p5.insn        = p3p4_q.insn;
  end

  p4p5 p4p5_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_p4p5 (p4p5),
      .o_p4p5 (p4p5_q)
  );

  /*
  // Hazard detection and pipeline control
  hazard_unit #(
      .HAZARD_TECHNIQUE(HAZARD_TECHNIQUE),
      .ENABLE_LOAD_USE_FORWARDING(ENABLE_LOAD_USE_FORWARDING)
  ) hazard_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),

      // ID stage
      .i_id_rs1   (p1p2_q.insn.r_type.rs1),
      .i_id_rs2   (p1p2_q.insn.r_type.rs2),
      .i_id_valid (1'b1),                      // TODO: Add proper valid signal
      .i_id_opcode(p1p2_q.insn.common.opcode),

      // EX stage
      .i_ex_rs1      (p2p3_q.insn.r_type.rs1),
      .i_ex_rs2      (p2p3_q.insn.r_type.rs2),
      .i_ex_valid    (1'b1),                                   // TODO: Add proper valid signal
      .i_ex_is_store (p2p3_q.insn.common.opcode == OP_STORE),
      .i_ex_is_branch(p2p3_q.insn.common.opcode == OP_BRANCH),

      // MEM stage
      .i_mem_rd       (p3p4_q.insn.r_type.rd),
      .i_mem_reg_write(p3p4_q.ctrl.p5.reg_wr_en),
      .i_mem_is_load  (p3p4_q.insn.common.opcode == OP_LOAD),
      .i_mem_valid    (1'b1),                                  // TODO: Add proper valid signal

      // WB stage
      .i_wb_rd       (p4p5_q.insn.r_type.rd),
      .i_wb_reg_write(p4p5_q.ctrl.p5.reg_wr_en),
      .i_wb_valid    (1'b1),                      // TODO: Add proper valid signal

      // Branch prediction (for future enhancement)
      .i_branch_taken     (1'b0),  // TODO: Add branch prediction
      .i_branch_mispredict(1'b0),  // TODO: Add branch prediction

      // Pipeline control outputs
      .o_stall_if         (stall_if),
      .o_stall_id         (stall_id),
      .o_stall_ex         (stall_ex),
      .o_flush_id         (flush_id),
      .o_flush_ex         (flush_ex),
      .o_enable_forwarding(enable_forwarding)
  );

  // Data forwarding unit
  forwarding_unit forwarding_u (
      // EX stage (current instruction)
      .i_ex_rs1     (p2p3_q.insn.r_type.rs1),
      .i_ex_rs2     (p2p3_q.insn.r_type.rs2),
      .i_ex_is_store(p2p3_q.insn.common.opcode == OP_STORE),

      // MEM stage (previous instruction)
      .i_mem_rd        (p3p4_q.insn.r_type.rd),
      .i_mem_reg_write (p3p4_q.ctrl.p5.reg_wr_en),
      .i_mem_alu_result(p3p4_q.alu_out),

      // WB stage (older instruction)
      .i_wb_rd        (p4p5_q.insn.r_type.rd),
      .i_wb_reg_write (p4p5_q.ctrl.p5.reg_wr_en),
      .i_wb_alu_result(p4p5_q.alu_out),
      .i_wb_mem_data  (p4p5_q.mem_rdata),
      .i_wb_mem_to_reg(p4p5_q.ctrl.p5.is_mem_to_reg),

      // Register file data
      .i_regfile_data1(p2p3_q.reg_rd_data1),
      .i_regfile_data2(p2p3_q.reg_rd_data2),

      // Forwarded outputs
      .o_forwarded_data1     (alu_in1_forwarded),
      .o_forwarded_data2     (alu_in2_forwarded),
      .o_forwarded_store_data(mem_wdata_forwarded)
  );
  */

  // Wire assignments after all signals are declared
  assign p4_reg_wr_data = p3p4_q.ctrl.p4.is_mem_to_reg ? mem_rdata : p3p4_q.alu_out;
  assign alu_in1        = enable_forwarding ? alu_in1_forwarded : p2p3_q.reg_rd_data1;
  assign alu_in2        = enable_forwarding ? alu_in2_forwarded : alu_in2_pre;
  assign alu_in2_pre    = p2p3_q.ctrl.p3.alu_src == ALUSRC_REG ? p2p3_q.reg_rd_data2 : p3_imm_se;
  assign mem_wdata      = mem_wdata_forwarded;

  // Combinational signal assignments
  assign p2_pc_next     = p1p2_q.pc + get_j_imm(p2_insn);
  assign p3_pc_next     = p2p3_q.pc + p3_imm_se;

endmodule
