// register file

module regfile #(
    parameter XW = 32
) (
    input  logic          clk,
    input  logic          rst_n,
    // read interface
    input  logic [   4:0] rd_addr1_ip,  // read register 1
    input  logic [   4:0] rd_addr2_ip,  // read register 2
    output logic [XW-1:0] rd_data1_op,
    output logic [XW-1:0] rd_data2_op,
    // write interface
    input  logic [XW-1:0] wr_data_ip,
    input  logic [   4:0] wr_addr_ip,   // write register
    input  logic          wr_en_ip
);

  logic [XW-1:0] x[31];
  logic [XW-1:0] rd_data1;
  logic [XW-1:0] rd_data2;

  logic [XW-1:0] next_rd_data1;
  logic [XW-1:0] next_rd_data2;

  logic [XW-1:0] x1;
  logic [XW-1:0] x2;

  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      for (i = 0; i < 31; i++) begin
        x[i] <= '0;
      end
      // next_rd_data1 <= {XW{1'b0}};
      // next_rd_data2 <= {XW{1'b0}};
      rd_data1 <= '0;
      rd_data2 <= '0;
    end else begin
      if (wr_en_ip) begin
        if (wr_addr_ip != 5'b0) begin  // protect against writes to x[0]
          x[wr_addr_ip-1] <= wr_data_ip;
        end
      end
      rd_data1 <= rd_addr1_ip == 0 ? '0 : x[rd_addr1_ip-1];
      rd_data2 <= rd_addr2_ip == 0 ? '0 : x[rd_addr2_ip-1];
    end
  end

  always_comb begin
    x1 = x[0];
    x2 = x[1];
  end

  // always_ff @(posedge clk) begin
  //   case (rd_addr1_ip)
  //     5'b0: next_rd_data1 <= {XW{1'b0}};
  //     wr_addr_ip:
  //     next_rd_data1 <= wr_data_ip;  // same cycle read and write supported (hazard prevention)
  //     default: next_rd_data1 <= rd_data1;
  //   endcase
  // end
  //
  // always_ff @(posedge clk) begin
  //   case (rd_addr2_ip)
  //     5'b0:       next_rd_data2 <= {XW{1'b0}};
  //     wr_addr_ip: next_rd_data2 <= wr_data_ip;
  //     default:    next_rd_data2 <= rd_data2;
  //   endcase
  // end

  assign rd_data1_op = rd_data1;
  assign rd_data2_op = rd_data2;

endmodule
