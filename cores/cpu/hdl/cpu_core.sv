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
  p1p2_t       p1p2_data;
  p2p3_t       p2p3_data;
  p3p4_t       p3p4_data;
  p4p5_t       p4p5_data;

  p1p2_t       p1p2_out;
  p2p3_t       p2p3_out;
  p3p4_t       p3p4_out;
  p4p5_t       p4p5_out;

  //------------------------------------------------------------------------------
  // Instruction pipeline
  //------------------------------------------------------------------------------

  insn_t       p1_insn;
  insn_t       p2_insn;
  insn_t       p3_insn;
  insn_t       p4_insn;
  insn_t       p5_insn;


  logic  [4:0] p1_rs1;  // most formats use same rs1 position
  logic  [4:0] p1_rs2;  // most formats use same rs2 position

  /* instruction decode, register file p1 out, p2 in */
  assign p2_insn = p1p2_out.insn;

  logic [31:0] p2_pc_next;  // JAL target address

  /* p2 out, p3 in */
  assign p3_insn = p2p3_out.insn;

  logic [31:0] p3_imm_se;
  logic [31:0] p3_alu_out;

  /* p3 out, p4 in */
  logic [31:0] p4_mem_rdata;
  assign p4_insn = p3p4_out.insn;
  logic [31:0] p3_pc_next;  // branch target address

  /* p4 out, p5 in */
  assign p5_insn = p4p5_out.insn;

  /* register file  */
  logic      [ 4:0] reg_rd_port1;  // decode from q1, pipeline register "absorbed"
  logic      [ 4:0] reg_rd_port2;
  logic      [31:0] reg_rd_data1;
  logic      [31:0] reg_rd_data2;
  logic      [ 4:0] reg_wr_port;
  logic      [31:0] reg_wr_data;

  logic      [31:0] p2_reg_rd_data1;  // alu ops
  logic      [31:0] p2_reg_rd_data2;  // alu ops or memory address
  logic      [ 4:0] p2_reg_wr_port;  // pipelined to p5
  logic      [31:0] p4_reg_wr_data;

  /* alu & ctrl */
  logic      [31:0] alu_in1;
  logic      [31:0] alu_in2;
  alu_op_t          alu_ctrl_ctrl;
  logic      [31:0] alu_out;
  logic      [31:0] alu_in1_pre;
  logic      [31:0] alu_in2_pre;
  alu_ctrl_t        ctrl_aluop;

  /* data memory */
  logic             ctrl_mem_ren;  // memory operations happen in Q4
  logic             ctrl_mem_wren;
  logic      [31:0] mem_addr;
  logic      [31:0] mem_wdata;
  logic      [31:0] mem_rdata;
  logic      [31:0] mem_wdata_forwarded;

  /* pipeline control signals */
  logic stall_if, stall_id, stall_ex;
  logic flush_id, flush_ex;
  logic             enable_forwarding;

  /* PC declaration */
  logic      [31:0] pc;  // need PC immediately in fetch
  logic      [31:0] pc_incr_last;
  logic      [31:0] pc_incr;


  /* main control unit */
  cpu_ctrl_t        p2_ctrl;

  /* forwarding unit */
  logic      [31:0] alu_in1_forwarded;
  logic      [31:0] alu_in2_forwarded;

  always_comb begin : sign_extend_immediate
    case (p2p3_out.insn.common.opcode)
      OP_ITYPE, OP_LOAD, OP_JALR: p3_imm_se = get_i_imm(p3_insn);
      OP_STORE:                   p3_imm_se = get_s_imm(p3_insn);
      OP_BRANCH:                  p3_imm_se = get_b_imm(p3_insn);
      OP_JAL:                     p3_imm_se = get_j_imm(p3_insn);
      default:                    p3_imm_se = get_i_imm(p3_insn);
    endcase
  end

  logic p2_pc_jal;
  always_comb begin
    pc = pc_incr_last;
    // Handle JAL and branch instructions
    if (p2_ctrl.p2.is_jal) begin
      pc = p2_pc_next;
    end
    else if (p3p4_out.ctrl.p4.is_branch) begin
      pc = p3p4_out.pc_next;
    end
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      pc_incr_last <= 0;
    end
    else begin
      pc_incr_last <= pc_incr;
    end
  end

  insnmem #(
      .SIZE(4096)
  ) insnmem_u (
      .i_clk           (i_clk),
      .i_rst_n         (i_rst_n),
      .i_pc            (pc),
      .o_insn          (p1_insn),
      .o_imem_exception(  /* unused */)
  );

  //------------------------------------------------------------------------------
  // Instruction decode (q2)
  //------------------------------------------------------------------------------

  alu alu_u (
      .i_alu_a        (alu_in1),
      .i_alu_b        (alu_in2),
      .i_alu_ctrl     (alu_ctrl_ctrl),
      .o_alu_out      (alu_out),
      .o_alu_exception(  /* unused */)
  );

  regfile regfile_u (
      .i_clk     (i_clk),
      .i_rst_n   (i_rst_n),
      .i_rd_addr1(reg_rd_port1),
      .i_rd_addr2(reg_rd_port2),
      .o_rd_data1(reg_rd_data1),
      .o_rd_data2(reg_rd_data2),
      .i_wr_addr (reg_wr_port),
      .i_wr_data (reg_wr_data),
      .i_wr_en   (p4p5_out.ctrl.p5.reg_wr_en)
  );

  control control_u (
      .i_opcode(p1p2_out.insn.common.opcode),
      .o_ctrl  (p2_ctrl)
  );

  aluctrl alucontrol_u (
      .i_aluop   (ctrl_aluop),
      .i_funct3  (p2p3_out.insn.r_type.funct3),
      .i_funct7_5(p2p3_out.insn.r_type.funct7[5]),
      .o_alu_ctrl(alu_ctrl_ctrl)
  );

  memory #(
      .PRELOAD(1),
      .PRELOAD_FILE("sim/dmem.hex")
  ) memory_u (
      .i_rst_n        (i_rst_n),
      .i_clk          (i_clk),
      .i_ctrl_mem_ren (ctrl_mem_ren),
      .i_ctrl_mem_wren(ctrl_mem_wren),
      .i_mem_addr     (mem_addr),
      .i_mem_wdata    (mem_wdata),
      .o_mem_rdata    (mem_rdata)
  );

  // Hazard detection and pipeline control
  hazard_unit #(
      .HAZARD_TECHNIQUE(HAZARD_TECHNIQUE),
      .ENABLE_LOAD_USE_FORWARDING(ENABLE_LOAD_USE_FORWARDING)
  ) hazard_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),

      // ID stage
      .i_id_rs1   (p1p2_out.insn.r_type.rs1),
      .i_id_rs2   (p1p2_out.insn.r_type.rs2),
      .i_id_valid (1'b1),                        // TODO: Add proper valid signal
      .i_id_opcode(p1p2_out.insn.common.opcode),

      // EX stage
      .i_ex_rs1      (p2p3_out.insn.r_type.rs1),
      .i_ex_rs2      (p2p3_out.insn.r_type.rs2),
      .i_ex_valid    (1'b1),                                     // TODO: Add proper valid signal
      .i_ex_is_store (p2p3_out.insn.common.opcode == OP_STORE),
      .i_ex_is_branch(p2p3_out.insn.common.opcode == OP_BRANCH),

      // MEM stage
      .i_mem_rd       (p3p4_out.insn.r_type.rd),
      .i_mem_reg_write(p3p4_out.ctrl.p5.reg_wr_en),
      .i_mem_is_load  (p3p4_out.insn.common.opcode == OP_LOAD),
      .i_mem_valid    (1'b1),                                    // TODO: Add proper valid signal

      // WB stage
      .i_wb_rd       (p4p5_out.insn.r_type.rd),
      .i_wb_reg_write(p4p5_out.ctrl.p5.reg_wr_en),
      .i_wb_valid    (1'b1),                        // TODO: Add proper valid signal

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
      .i_ex_rs1     (p2p3_out.insn.r_type.rs1),
      .i_ex_rs2     (p2p3_out.insn.r_type.rs2),
      .i_ex_is_store(p2p3_out.insn.common.opcode == OP_STORE),

      // MEM stage (previous instruction)
      .i_mem_rd        (p3p4_out.insn.r_type.rd),
      .i_mem_reg_write (p3p4_out.ctrl.p5.reg_wr_en),
      .i_mem_alu_result(p3p4_out.alu_out),

      // WB stage (older instruction)
      .i_wb_rd        (p4p5_out.insn.r_type.rd),
      .i_wb_reg_write (p4p5_out.ctrl.p5.reg_wr_en),
      .i_wb_alu_result(p4p5_out.alu_out),
      .i_wb_mem_data  (p4p5_out.mem_rdata),
      .i_wb_mem_to_reg(p4p5_out.ctrl.p5.is_mem_to_reg),

      // Register file data
      .i_regfile_data1(p2p3_out.reg_rd_data1),
      .i_regfile_data2(p2p3_out.reg_rd_data2),

      // Forwarded outputs
      .o_forwarded_data1     (alu_in1_forwarded),
      .o_forwarded_data2     (alu_in2_forwarded),
      .o_forwarded_store_data(mem_wdata_forwarded)
  );

  // Wire assignments after all signals are declared
  assign p3_alu_out = alu_out;
  assign p4_mem_rdata = mem_rdata;
  assign reg_wr_port = p4p5_out.reg_wr_port;
  assign reg_wr_data = p4_reg_wr_data;
  assign p4_reg_wr_data = p3p4_out.ctrl.p5.is_mem_to_reg ? mem_rdata : p3p4_out.alu_out;
  assign alu_in1 = enable_forwarding ? alu_in1_forwarded : alu_in1_pre;
  assign alu_in2 = enable_forwarding ? alu_in2_forwarded : alu_in2_pre;
  assign alu_in1_pre = p2p3_out.reg_rd_data1;
  assign alu_in2_pre = p2p3_out.ctrl.p3.alu_src == ALUSRC_REG ? p2p3_out.reg_rd_data2 : p3_imm_se;
  assign ctrl_aluop = p2p3_out.ctrl.p3.alu_ctrl;
  assign ctrl_mem_ren = p3p4_out.ctrl.p4.mem_re;
  assign ctrl_mem_wren = p3p4_out.ctrl.p4.mem_we;
  assign mem_addr = p3_alu_out;
  assign mem_wdata = mem_wdata_forwarded;

  // Combinational signal assignments
  assign p1_rs1 = p1_insn.common.opcode == OP_JAL ?
      '0 : (p1_insn.common.opcode == OP_BRANCH || p1_insn.common.opcode == OP_STORE) ?
      p1_insn.s_type.rs1 : p1_insn.r_type.rs1;
  assign p1_rs2 = p1_insn.common.opcode == OP_JAL ?
      '0 : (p1_insn.common.opcode == OP_BRANCH || p1_insn.common.opcode == OP_STORE) ?
      p1_insn.s_type.rs2 : p1_insn.r_type.rs2;
  assign p2_pc_next = p1p2_out.pc + get_j_imm(p2_insn);
  assign p3_pc_next = p2p3_out.pc + p3_imm_se;
  assign reg_rd_port1 = p1_rs1;
  assign reg_rd_port2 = p1_rs2;
  assign p2_reg_rd_data1 = reg_rd_data1;
  assign p2_reg_rd_data2 = reg_rd_data2;
  assign p2_reg_wr_port = p1p2_out.insn.r_type.rd;
  assign pc_incr = pc + 4;

  /* pipeline registers */

  // P1->P2 pipeline struct population
  always_comb begin
    p1p2_data = '{insn: p1_insn, pc: pc, pc_incr: pc_incr};
  end

  p1p2 p1p2_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_p1p2 (p1p2_data),
      .o_p1p2 (p1p2_out)
  );

  // P1->P2 outputs used directly from struct

  // P2->P3 pipeline struct population
  always_comb begin
    p2p3_data = '{
        pc: p1p2_out.pc,
        pc_incr: p1p2_out.pc_incr,
        reg_rd_data1: p2_reg_rd_data1,
        reg_rd_data2: p2_reg_rd_data2,
        reg_wr_port: p1p2_out.insn.r_type.rd,
        ctrl: ctrl_q2,
        insn: p1p2_out.insn
    };
  end

  p2p3 p2p3_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_p2p3 (p2p3_data),
      .o_p2p3 (p2p3_out)
  );

  // P2->P3 outputs used directly from struct

  // P3->P4 pipeline struct population
  always_comb begin
    p3p4_data = '{
        pc_next: p3_pc_next,
        alu_out: p3_alu_out,
        reg_rd_data2: p2p3_out.reg_rd_data2,
        reg_wr_port: p2p3_out.reg_wr_port,
        ctrl: p2p3_out.ctrl,
        insn: p2p3_out.insn
    };
  end

  p3p4 p3p4_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_p3p4 (p3p4_data),
      .o_p3p4 (p3p4_out)
  );

  // P3->P4 outputs used directly from struct

  // P4->P5 pipeline struct population
  always_comb begin
    p4p5_data = '{
        alu_out: p3p4_out.alu_out,
        mem_rdata: p4_mem_rdata,
        reg_wr_port: p3p4_out.reg_wr_port,
        ctrl: p3p4_out.ctrl,
        insn: p3p4_out.insn
    };
  end

  p4p5 p4p5_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_p4p5 (p4p5_data),
      .o_p4p5 (p4p5_out)
  );

  // P4->P5 outputs used directly from struct



endmodule
