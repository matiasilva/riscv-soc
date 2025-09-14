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

// Module  : hazard_unit
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Pipeline hazard detection and control unit with configurable hazard handling techniques
//   Supports different performance/complexity tradeoffs for hazard resolution
//
// Hazard Handling Techniques:
//   0: STALL_ONLY     - Always stall on hazards (simplest, lowest performance)
//   1: FORWARD_ONLY   - Always forward when possible (highest performance, most complex)
//   2: HYBRID         - Forward for ALU hazards, stall for load-use hazards
//   3: AGGRESSIVE     - Forward + branch prediction + speculative execution

`include "cpu_types.vh"

module hazard_unit #(
    parameter int HAZARD_TECHNIQUE = 0,  // 0=STALL_ONLY, 1=FORWARD_ONLY, 2=HYBRID, 3=AGGRESSIVE
    parameter int ENABLE_LOAD_USE_FORWARDING = 1  // Enable forwarding for load-use hazards
) (
    input logic i_clk,
    input logic i_rst_n,

    // Current instruction info (ID stage)
    input logic    [4:0] i_id_rs1,    // Source register 1
    input logic    [4:0] i_id_rs2,    // Source register 2
    input logic          i_id_valid,  // Instruction is valid
    input opcode_t       i_id_opcode, // Instruction opcode

    // Current instruction info (EX stage)
    input logic [4:0] i_ex_rs1,       // Source register 1
    input logic [4:0] i_ex_rs2,       // Source register 2
    input logic       i_ex_valid,     // Instruction is valid
    input logic       i_ex_is_store,  // Is store operation
    input logic       i_ex_is_branch, // Is branch operation

    // Previous instruction info (MEM stage)
    input logic [4:0] i_mem_rd,         // Destination register
    input logic       i_mem_reg_write,  // Will write to register
    input logic       i_mem_is_load,    // Is load operation
    input logic       i_mem_valid,      // Instruction is valid

    // Older instruction info (WB stage)
    input logic [4:0] i_wb_rd,         // Destination register
    input logic       i_wb_reg_write,  // Will write to register
    input logic       i_wb_valid,      // Instruction is valid

    // Branch prediction inputs (for AGGRESSIVE mode)
    input logic i_branch_taken,      // Branch was taken
    input logic i_branch_mispredict, // Branch misprediction

    // Pipeline control outputs
    output logic o_stall_if,          // Stall instruction fetch
    output logic o_stall_id,          // Stall instruction decode
    output logic o_stall_ex,          // Stall execute stage
    output logic o_flush_id,          // Flush instruction decode
    output logic o_flush_ex,          // Flush execute stage
    output logic o_enable_forwarding  // Enable forwarding unit
);


  // Hazard detection logic
  logic raw_hazard_rs1_mem;  // RAW hazard on rs1 with MEM stage
  logic raw_hazard_rs2_mem;  // RAW hazard on rs2 with MEM stage
  logic raw_hazard_rs1_wb;  // RAW hazard on rs1 with WB stage
  logic raw_hazard_rs2_wb;  // RAW hazard on rs2 with WB stage
  logic load_use_hazard_detected;
  logic data_hazard_detected;
  logic control_hazard_detected;

  // RAW hazard detection
  always_comb begin
    // EX/MEM hazards
    raw_hazard_rs1_mem = i_mem_reg_write && i_mem_valid && (i_mem_rd != 5'b0) &&
        (i_mem_rd == i_ex_rs1) && i_ex_valid;
    raw_hazard_rs2_mem = i_mem_reg_write && i_mem_valid && (i_mem_rd != 5'b0) &&
        (i_mem_rd == i_ex_rs2) && i_ex_valid;

    // MEM/WB hazards
    raw_hazard_rs1_wb = i_wb_reg_write && i_wb_valid && (i_wb_rd != 5'b0) &&
        (i_wb_rd == i_ex_rs1) && i_ex_valid && !(raw_hazard_rs1_mem);  // EX/MEM has priority
    raw_hazard_rs2_wb = i_wb_reg_write && i_wb_valid && (i_wb_rd != 5'b0) &&
        (i_wb_rd == i_ex_rs2) && i_ex_valid && !(raw_hazard_rs2_mem);  // EX/MEM has priority

    // Load-use hazard (ID/EX with EX/MEM)
    load_use_hazard_detected = i_mem_is_load && i_mem_valid && i_id_valid && (i_mem_rd != 5'b0) &&
        ((i_mem_rd == i_id_rs1) || (i_mem_rd == i_id_rs2));

    // Overall data hazard detection
    data_hazard_detected = raw_hazard_rs1_mem || raw_hazard_rs2_mem || raw_hazard_rs1_wb ||
        raw_hazard_rs2_wb || load_use_hazard_detected;

    // Control hazards (branches, jumps)
    control_hazard_detected = i_ex_is_branch || i_branch_mispredict;
  end

  // Hazard handling based on selected technique
  always_comb begin
    // Default values
    o_stall_if          = 1'b0;
    o_stall_id          = 1'b0;
    o_stall_ex          = 1'b0;
    o_flush_id          = 1'b0;
    o_flush_ex          = 1'b0;
    o_enable_forwarding = 1'b0;

    case (HAZARD_TECHNIQUE)
      // STALL_ONLY: Always stall on any hazard
      0: begin
        if (data_hazard_detected || load_use_hazard_detected) begin
          o_stall_if = 1'b1;
          o_stall_id = 1'b1;
          o_flush_ex = 1'b1;  // Insert bubble in EX stage
        end
        if (control_hazard_detected) begin
          o_flush_id = 1'b1;
          o_flush_ex = 1'b1;
        end
        o_enable_forwarding = 1'b0;
      end

      // FORWARD_ONLY: Always forward when possible, minimal stalling
      1: begin
        o_enable_forwarding = 1'b1;

        // Only stall for load-use hazards if forwarding is disabled
        if (load_use_hazard_detected && !ENABLE_LOAD_USE_FORWARDING) begin
          o_stall_if = 1'b1;
          o_stall_id = 1'b1;
          o_flush_ex = 1'b1;
        end

        // Handle control hazards
        if (control_hazard_detected) begin
          o_flush_id = 1'b1;
          o_flush_ex = 1'b1;
        end
      end

      // HYBRID: Forward for ALU hazards, stall for load-use
      2: begin
        o_enable_forwarding = 1'b1;

        // Always stall for load-use hazards
        if (load_use_hazard_detected) begin
          o_stall_if = 1'b1;
          o_stall_id = 1'b1;
          o_flush_ex = 1'b1;
        end

        // Handle control hazards
        if (control_hazard_detected) begin
          o_flush_id = 1'b1;
          o_flush_ex = 1'b1;
        end
      end

      // AGGRESSIVE: Forward + branch prediction + speculation
      3: begin
        o_enable_forwarding = 1'b1;

        // Only stall for unresolvable hazards
        if (load_use_hazard_detected && !ENABLE_LOAD_USE_FORWARDING) begin
          o_stall_if = 1'b1;
          o_stall_id = 1'b1;
          o_flush_ex = 1'b1;
        end

        // Only flush on branch misprediction
        if (i_branch_mispredict) begin
          o_flush_id = 1'b1;
          o_flush_ex = 1'b1;
        end
      end

      default: begin
        // Default to FORWARD_ONLY
        o_enable_forwarding = 1'b1;
      end
    endcase
  end


endmodule
