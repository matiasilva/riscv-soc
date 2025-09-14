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

// Module  : forwarding_unit
// Author  : Matias Wang Silva
// Date    : 11/9/2025
//
// Description:
//   Data forwarding unit for resolving pipeline hazards in RISC-V processor
//   Detects RAW hazards and selects appropriate data sources to forward
//
// Forwarding Sources:
//   - REGFILE: Data read from register file (no forwarding needed)
//   - EX_MEM:  Data from EX/MEM pipeline register (previous instruction's ALU result)
//   - MEM_WB:  Data from MEM/WB pipeline register (older instruction's result or memory data)

`include "cpu_types.vh"

module forwarding_unit (
    // Current instruction info (in EX stage)
    input logic [4:0] i_ex_rs1,      // Source register 1 address
    input logic [4:0] i_ex_rs2,      // Source register 2 address
    input logic       i_ex_is_store, // Current instruction is store operation

    // Previous instruction info (in MEM stage)
    input logic [ 4:0] i_mem_rd,         // Destination register address
    input logic        i_mem_reg_write,  // Will write to register
    input logic [31:0] i_mem_alu_result, // ALU result from MEM stage

    // Older instruction info (in WB stage)
    input logic [ 4:0] i_wb_rd,          // Destination register address
    input logic        i_wb_reg_write,   // Will write to register
    input logic [31:0] i_wb_alu_result,  // ALU result from WB stage
    input logic [31:0] i_wb_mem_data,    // Memory data from WB stage
    input logic        i_wb_mem_to_reg,  // Select memory data vs ALU result

    // Original data from register file
    input logic [31:0] i_regfile_data1,  // Register file output 1
    input logic [31:0] i_regfile_data2,  // Register file output 2

    // Forwarded outputs
    output logic [31:0] o_forwarded_data1,      // Forwarded data for ALU input 1
    output logic [31:0] o_forwarded_data2,      // Forwarded data for ALU input 2
    output logic [31:0] o_forwarded_store_data  // Forwarded data for store operations
);

  // Internal forwarding control signals
  typedef enum logic [1:0] {
    FWD_REGFILE = 2'b00,  // Use data from register file
    FWD_EX_MEM  = 2'b01,  // Forward from EX/MEM pipeline register
    FWD_MEM_WB  = 2'b10   // Forward from MEM/WB pipeline register
  } forward_src_t;

  forward_src_t forward_rs1_src;
  forward_src_t forward_rs2_src;
  forward_src_t forward_store_src;

  // WB stage data selection (ALU result or memory data)
  logic [31:0] wb_result_data;
  assign wb_result_data = i_wb_mem_to_reg ? i_wb_mem_data : i_wb_alu_result;

  // Hazard detection for RS1 (ALU input 1)
  always_comb begin
    forward_rs1_src = FWD_REGFILE;  // Default: no forwarding

    // Check for EX/MEM hazard (most recent, highest priority)
    if (i_mem_reg_write && (i_mem_rd != 5'b0) && (i_mem_rd == i_ex_rs1)) begin
      forward_rs1_src = FWD_EX_MEM;
    end
    // Check for MEM/WB hazard (older, lower priority)
    else if (i_wb_reg_write && (i_wb_rd != 5'b0) && (i_wb_rd == i_ex_rs1)) begin
      forward_rs1_src = FWD_MEM_WB;
    end
  end

  // Hazard detection for RS2 (ALU input 2)
  always_comb begin
    forward_rs2_src = FWD_REGFILE;  // Default: no forwarding

    // Check for EX/MEM hazard (most recent, highest priority)
    if (i_mem_reg_write && (i_mem_rd != 5'b0) && (i_mem_rd == i_ex_rs2)) begin
      forward_rs2_src = FWD_EX_MEM;
    end
    // Check for MEM/WB hazard (older, lower priority)
    // Note: Don't forward for store operations to avoid incorrect ALU forwarding
    else if (i_wb_reg_write && (i_wb_rd != 5'b0) && (i_wb_rd == i_ex_rs2) && !i_ex_is_store) begin
      forward_rs2_src = FWD_MEM_WB;
    end
  end

  // Hazard detection for store data
  always_comb begin
    forward_store_src = FWD_REGFILE;  // Default: no forwarding

    // Check for EX/MEM hazard (most recent, highest priority)
    if (i_mem_reg_write && (i_mem_rd != 5'b0) && (i_mem_rd == i_ex_rs2)) begin
      forward_store_src = FWD_EX_MEM;
    end
    // Check for MEM/WB hazard (older, lower priority)
    else if (i_wb_reg_write && (i_wb_rd != 5'b0) && (i_wb_rd == i_ex_rs2)) begin
      forward_store_src = FWD_MEM_WB;
    end
  end

  // Forwarding multiplexers
  always_comb begin
    case (forward_rs1_src)
      FWD_REGFILE: o_forwarded_data1 = i_regfile_data1;
      FWD_EX_MEM:  o_forwarded_data1 = i_mem_alu_result;
      FWD_MEM_WB:  o_forwarded_data1 = wb_result_data;
      default:     o_forwarded_data1 = i_regfile_data1;
    endcase
  end

  always_comb begin
    case (forward_rs2_src)
      FWD_REGFILE: o_forwarded_data2 = i_regfile_data2;
      FWD_EX_MEM:  o_forwarded_data2 = i_mem_alu_result;
      FWD_MEM_WB:  o_forwarded_data2 = wb_result_data;
      default:     o_forwarded_data2 = i_regfile_data2;
    endcase
  end

  always_comb begin
    case (forward_store_src)
      FWD_REGFILE: o_forwarded_store_data = i_regfile_data2;
      FWD_EX_MEM:  o_forwarded_store_data = i_mem_alu_result;
      FWD_MEM_WB:  o_forwarded_store_data = wb_result_data;
      default:     o_forwarded_store_data = i_regfile_data2;
    endcase
  end


endmodule
