/*
[ctrl]
4'b0000 ADD
4'b1000 SUB
4'b0010 SLT
4'b0011 SLTU
4'b0111 AND
4'b0110 OR
4'b0100 XOR
4'b0001 SLL
4'b0101 SRL
4'b1101 SRA
*/

module alu (
    input  [31:0] i_alu_a,
    input  [31:0] i_alu_b,
    input  [ 3:0] i_aluctrl_ctrl,
    output [31:0] o_alu_out
);

  localparam OP_ADD = 4'b0000;
  localparam OP_SUB = 4'b1000;
  localparam OP_SLT = 4'b0010;
  localparam OP_SLTU = 4'b0011;
  localparam OP_AND = 4'b0111;
  localparam OP_OR = 4'b0110;
  localparam OP_XOR = 4'b0100;
  localparam OP_SLL = 4'b0001;
  localparam OP_SRL = 4'b0101;
  localparam OP_SRA = 4'b1101;

  wire [31:0] diff = i_alu_a - i_alu_b;
  wire [ 4:0] shamt = i_alu_b[4:0];

  reg  [31:0] result;

  always @(*) begin
    result = 32'b0;
    case (i_aluctrl_ctrl)
      OP_ADD:  result = i_alu_a + i_alu_b;
      OP_SUB:  result = diff;
      OP_SLT: begin
        if (i_alu_a[31] ^ i_alu_b[31]) begin
          result = i_alu_a[31];
        end else begin
          result = diff[31];
        end
      end
      OP_SLTU: result = i_alu_a < i_alu_b;
      OP_AND:  result = i_alu_a & i_alu_b;
      OP_OR:   result = i_alu_a | i_alu_b;
      OP_XOR:  result = i_alu_a ^ i_alu_b;
      OP_SLL:  result = i_alu_a << shamt;
      OP_SRL:  result = i_alu_a >> shamt;
      OP_SRA:  result = $signed(i_alu_a) >>> shamt;
    endcase
  end

  assign o_alu_out = result;

endmodule
