// register file

module regfile (
    input         clk,
    input         rst_n,
    // read interface
    input  [ 4:0] rd_port1_i,       // read register 1
    input  [ 4:0] rd_port2_i,       // read register 2
    output [31:0] rd_data1_o,
    output [31:0] rd_data2_o,
    // write interface
    input  [31:0] wr_data_i,
    input  [ 4:0] wr_port_i,        // write register
    input         ctrl_reg_wr_en_i
);

  // we don't care about the contents of x[0]
  // as we hard wire this to 0 on a read
  // but the register still exists for simplicity
  reg [31:0] x[31:0];
  reg [31:0] next_rd_data1;
  reg [31:0] next_rd_data2;

  wire isrd_r1zero = !(|rd_port1_i);
  wire isrd_r2zero = !(|rd_port2_i);

  integer i;

  initial begin
    for (i = 0; i < 32; i++) begin
      x[i] = 32'b0;
    end
  end

  always @(*) begin
    // simultaneous read and write supported
    if (ctrl_reg_wr_en_i) begin
      if (wr_port_i !== 5'b0) begin
        x[wr_port_i] = wr_data_i;
      end
    end
    next_rd_data1 = x[rd_port1_i];
    next_rd_data2 = x[rd_port2_i];
  end

  assign rd_data1_o = isrd_r1zero ? 32'b0 : next_rd_data1;
  assign rd_data2_o = isrd_r2zero ? 32'b0 : next_rd_data2;

endmodule
