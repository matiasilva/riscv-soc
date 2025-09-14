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
//     Q1: Instruction fetch
//     Q2: Instruction decode / register file read
//     Q3: Execute / ALU operations
//     Q4: Memory access
//     Q5: Write back
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

  /* Pipeline register structs - declared early */
  q1q2_t        q1q2_data;
  q2q3_t        q2q3_data;
  q3q4_t        q3q4_data;
  q4q5_t        q4q5_data;

  q1q2_t        q1q2_out;
  q2q3_t        q2q3_out;
  q3q4_t        q3q4_out;
  q4q5_t        q4q5_out;

  /* instruction fetch q1 */
  logic  [31:0] insn_raw_q1;  // from insnmem (q1)
  insn_t        insn_q1;
  assign insn_q1.raw = insn_raw_q1;
  logic  [4:0] rs1_q1;  // most formats use same rs1 position
  logic  [4:0] rs2_q1;  // most formats use same rs2 position

  /* instruction decode, register file q1 out, q2 in */
  insn_t       insn_q2;
  assign insn_q2.raw = q1q2_out.insn;

  logic  [ 4:0] rd_q2;  // rd position is same for R, I, U, J types

  logic  [31:0] pc_next_q2;  // JAL target address

  /* q2 out, q3 in */
  insn_t        insn_q3;
  assign insn_q3.raw = q2q3_out.insn;

  logic  [31:0] imm_se_q3;
  logic  [31:0] alu_out_q3;

  /* q3 out, q4 in */
  logic  [31:0] mem_rdata_q4;
  insn_t        insn_q4;
  assign insn_q4.raw = q3q4_out.insn;
  logic  [31:0] pc_next_q3;  // branch target address

  /* q4 out, q5 in */
  insn_t        insn_q5;
  assign insn_q5.raw = q4q5_out.insn;

  /* register file  */
  logic      [ 4:0] reg_rd_port1;  // decode from q1, pipeline register "absorbed"
  logic      [ 4:0] reg_rd_port2;
  logic      [31:0] reg_rd_data1;
  logic      [31:0] reg_rd_data2;
  logic      [ 4:0] reg_wr_port;
  logic      [31:0] reg_wr_data;

  logic      [31:0] reg_rd_data1_q2;  // alu ops
  logic      [31:0] reg_rd_data2_q2;  // alu ops or memory address
  logic      [ 4:0] reg_wr_port_q2;  // pipelined to q5
  logic      [31:0] reg_wr_data_q4;

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
  cpu_ctrl_t        ctrl_q2;

  /* forwarding unit */
  logic      [31:0] alu_in1_forwarded;
  logic      [31:0] alu_in2_forwarded;

  insnmem #(
      .SIZE(4096)
  ) insnmem_u (
      .i_clk           (i_clk),
      .i_rst_n         (i_rst_n),
      .i_pc            (pc),
      .o_insn          (insn_raw_q1),
      .o_imem_exception(  /* unused */)
  );

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
      .i_wr_en   (q4q5_out.ctrl.q5.reg_wr_en)
  );

  control control_u (
      .i_opcode(opcode_t'(q1q2_out.insn[6:0])),
      .o_ctrl  (ctrl_q2)
  );

  aluctrl alucontrol_u (
      .i_aluop   (ctrl_aluop),
      .i_funct3  (q2q3_out.insn[14:12]),
      .i_funct7_5(q2q3_out.insn[30]),
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
      .i_id_rs1   (q1q2_out.insn[19:15]),
      .i_id_rs2   (q1q2_out.insn[24:20]),
      .i_id_valid (1'b1),                          // TODO: Add proper valid signal
      .i_id_opcode(opcode_t'(q1q2_out.insn[6:0])),

      // EX stage
      .i_ex_rs1      (q2q3_out.insn[19:15]),
      .i_ex_rs2      (q2q3_out.insn[24:20]),
      .i_ex_valid    (1'b1),                                       // TODO: Add proper valid signal
      .i_ex_is_store (opcode_t'(q2q3_out.insn[6:0]) == OP_STORE),
      .i_ex_is_branch(opcode_t'(q2q3_out.insn[6:0]) == OP_BRANCH),

      // MEM stage
      .i_mem_rd       (q3q4_out.insn[11:7]),
      .i_mem_reg_write(q3q4_out.ctrl.q5.reg_wr_en),
      .i_mem_is_load  (opcode_t'(q3q4_out.insn[6:0]) == OP_LOAD),
      .i_mem_valid    (1'b1),                                      // TODO: Add proper valid signal

      // WB stage
      .i_wb_rd       (q4q5_out.insn[11:7]),
      .i_wb_reg_write(q4q5_out.ctrl.q5.reg_wr_en),
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
      .i_ex_rs1     (q2q3_out.insn[19:15]),
      .i_ex_rs2     (q2q3_out.insn[24:20]),
      .i_ex_is_store(opcode_t'(q2q3_out.insn[6:0]) == OP_STORE),

      // MEM stage (previous instruction)
      .i_mem_rd        (q3q4_out.insn[11:7]),
      .i_mem_reg_write (q3q4_out.ctrl.q5.reg_wr_en),
      .i_mem_alu_result(q3q4_out.alu_out),

      // WB stage (older instruction)
      .i_wb_rd        (q4q5_out.insn[11:7]),
      .i_wb_reg_write (q4q5_out.ctrl.q5.reg_wr_en),
      .i_wb_alu_result(q4q5_out.alu_out),
      .i_wb_mem_data  (q4q5_out.mem_rdata),
      .i_wb_mem_to_reg(q4q5_out.ctrl.q5.is_mem_to_reg),

      // Register file data
      .i_regfile_data1(q2q3_out.reg_rd_data1),
      .i_regfile_data2(q2q3_out.reg_rd_data2),

      // Forwarded outputs
      .o_forwarded_data1     (alu_in1_forwarded),
      .o_forwarded_data2     (alu_in2_forwarded),
      .o_forwarded_store_data(mem_wdata_forwarded)
  );

  // Wire assignments after all signals are declared
  assign alu_out_q3 = alu_out;
  assign mem_rdata_q4 = mem_rdata;
  assign reg_wr_port = q4q5_out.reg_wr_port;
  assign reg_wr_data = reg_wr_data_q4;
  assign reg_wr_data_q4 = q3q4_out.ctrl.q5.is_mem_to_reg ? mem_rdata : q3q4_out.alu_out;
  assign alu_in1 = enable_forwarding ? alu_in1_forwarded : alu_in1_pre;
  assign alu_in2 = enable_forwarding ? alu_in2_forwarded : alu_in2_pre;
  assign alu_in1_pre = q2q3_out.reg_rd_data1;
  assign alu_in2_pre = q2q3_out.ctrl.q3.alu_src == ALUSRC_REG ? q2q3_out.reg_rd_data2 : imm_se_q3;
  assign ctrl_aluop = q2q3_out.ctrl.q3.alu_ctrl;
  assign ctrl_mem_ren = q3q4_out.ctrl.q4.mem_re;
  assign ctrl_mem_wren = q3q4_out.ctrl.q4.mem_we;
  assign mem_addr = alu_out_q3;
  assign mem_wdata = mem_wdata_forwarded;

  // Combinational signal assignments
  assign rs1_q1 = insn_q1.common.opcode == OP_JAL ?
      '0 : (insn_q1.common.opcode == OP_BRANCH || insn_q1.common.opcode == OP_STORE) ?
      insn_q1.s_type.rs1 : insn_q1.r_type.rs1;
  assign rs2_q1 = insn_q1.common.opcode == OP_JAL ?
      '0 : (insn_q1.common.opcode == OP_BRANCH || insn_q1.common.opcode == OP_STORE) ?
      insn_q1.s_type.rs2 : insn_q1.r_type.rs2;
  assign rd_q2 = q1q2_out.insn[11:7];
  assign pc_next_q2 = q1q2_out.pc + get_j_imm(insn_q2);
  assign pc_next_q3 = q2q3_out.pc + imm_se_q3;
  assign reg_rd_port1 = rs1_q1;
  assign reg_rd_port2 = rs2_q1;
  assign reg_rd_data1_q2 = reg_rd_data1;
  assign reg_rd_data2_q2 = reg_rd_data2;
  assign reg_wr_port_q2 = rd_q2;
  assign pc_incr = pc + 4;

  /* pipeline registers */

  // Q1->Q2 pipeline struct population
  always_comb begin
    q1q2_data = '{insn: insn_raw_q1, pc: pc, pc_incr: pc_incr};
  end

  q1q2 q1q2_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_q1q2 (q1q2_data),
      .o_q1q2 (q1q2_out)
  );

  // Q1->Q2 outputs used directly from struct

  // Q2->Q3 pipeline struct population
  always_comb begin
    q2q3_data = '{
        pc: q1q2_out.pc,
        pc_incr: q1q2_out.pc_incr,
        reg_rd_data1: reg_rd_data1_q2,
        reg_rd_data2: reg_rd_data2_q2,
        reg_wr_port: rd_q2,
        ctrl: cpu_ctrl_t'(ctrl_q2),
        insn: q1q2_out.insn
    };
  end

  q2q3 q2q3_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_q2q3 (q2q3_data),
      .o_q2q3 (q2q3_out)
  );

  // Q2->Q3 outputs used directly from struct

  // Q3->Q4 pipeline struct population
  always_comb begin
    q3q4_data = '{
        pc_next: pc_next_q3,
        alu_out: alu_out_q3,
        reg_rd_data2: q2q3_out.reg_rd_data2,
        reg_wr_port: q2q3_out.reg_wr_port,
        ctrl: q2q3_out.ctrl,
        insn: q2q3_out.insn
    };
  end

  q3q4 q3q4_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_q3q4 (q3q4_data),
      .o_q3q4 (q3q4_out)
  );

  // Q3->Q4 outputs used directly from struct

  // Q4->Q5 pipeline struct population
  always_comb begin
    q4q5_data = '{
        alu_out: q3q4_out.alu_out,
        mem_rdata: mem_rdata_q4,
        reg_wr_port: q3q4_out.reg_wr_port,
        ctrl: q3q4_out.ctrl,
        insn: q3q4_out.insn
    };
  end

  q4q5 q4q5_u (
      .i_clk  (i_clk),
      .i_rst_n(i_rst_n),
      .i_q4q5 (q4q5_data),
      .o_q4q5 (q4q5_out)
  );

  // Q4->Q5 outputs used directly from struct

  // Immediate extraction based on instruction type
  always_comb begin
    case (opcode_t'(q2q3_out.insn[6:0]))
      OP_ITYPE, OP_LOAD, OP_JALR: imm_se_q3 = get_i_imm(insn_q3);
      OP_STORE:                   imm_se_q3 = get_s_imm(insn_q3);
      OP_BRANCH:                  imm_se_q3 = get_b_imm(insn_q3);
      OP_JAL:                     imm_se_q3 = get_j_imm(insn_q3);
      default:                    imm_se_q3 = get_i_imm(insn_q3);
    endcase
  end

  logic pc_jal_q2;
  always_comb begin
    pc = pc_incr_last;
    // Handle JAL and branch instructions
    if (ctrl_q2.q2.is_jal) begin
      pc = pc_next_q2;
    end
    else if (q3q4_out.ctrl.q4.is_branch) begin
      pc = q3q4_out.pc_next;
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

endmodule
