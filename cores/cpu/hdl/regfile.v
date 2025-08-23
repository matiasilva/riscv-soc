// register file

module regfile (
    input         clk,
    input         rst_n,
    // read interface
    input  [ 4:0] rd_port1_ip,       // read register 1
    input  [ 4:0] rd_port2_ip,       // read register 2
    output [31:0] rd_data1_op,
    output [31:0] rd_data2_op,
    // write interface
    input  [31:0] wr_data_ip,
    input  [ 4:0] wr_port_ip,        // write register
    input         ctrl_reg_wr_en_ip
);

  // we don't care about the contents of x[0]
  // as we hard wire this to 0 on a read
  // but the register still exists for simplicity
  reg [31:0] x[31:0];
  reg [31:0] rd_data1;
  reg [31:0] rd_data2;

  reg [31:0] next_rd_data1;
  reg [31:0] next_rd_data2;

  integer i;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      for (i = 0; i < 32; i++) begin
        x[i] <= 32'b0;
      end
      next_rd_data1 <= 32'b0;
      next_rd_data2 <= 32'b0;
      rd_data1 <= 32'b0;
      rd_data2 <= 32'b0;
    end else begin
      if (ctrl_reg_wr_en_ip) begin
        if (wr_port_ip !== 5'b0) begin
          x[wr_port_ip] <= wr_data_ip;
        end
      end
      rd_data1 <= x[rd_port1_ip];
      rd_data2 <= x[rd_port2_ip];
    end
  end

  always @(posedge clk) begin
    case (rd_port1_ip)
      5'b0: next_rd_data1 <= 32'b0;
      wr_port_ip:
      next_rd_data1 <= wr_data_ip;  // same cycle read and write supported (hazard prevention)
      default: next_rd_data1 <= rd_data1;
    endcase
  end

  always @(posedge clk) begin
    case (rd_port2_ip)
      5'b0:      next_rd_data2 <= 32'b0;
      wr_port_ip: next_rd_data2 <= wr_data_ip;
      default:   next_rd_data2 <= rd_data2;
    endcase
  end

  assign rd_data1_op = next_rd_data1;
  assign rd_data2_op = next_rd_data2;

endmodule
