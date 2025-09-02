// register file

module regfile #(
    parameter int XW = 32
) (
    input  logic          i_clk,
    input  logic          i_rst_n,
    // read interface
    input  logic [   4:0] i_rd_addr1,  // read register 1
    input  logic [   4:0] i_rd_addr2,  // read register 2
    output logic [XW-1:0] o_rd_data1,
    output logic [XW-1:0] o_rd_data2,
    // write interface
    input  logic [XW-1:0] i_wr_data,
    input  logic [   4:0] i_wr_addr,   // write register
    input  logic          i_wr_en
);

  logic [XW-1:0] x[31];
  logic [XW-1:0] rd_data1;
  logic [XW-1:0] rd_data2;

  logic [XW-1:0] next_rd_data1;
  logic [XW-1:0] next_rd_data2;

  integer i;

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      for (i = 0; i < 31; i++) begin
        x[i] <= '0;
      end
      // next_rd_data1 <= {XW{1'b0}};
      // next_rd_data2 <= {XW{1'b0}};
      rd_data1 <= '0;
      rd_data2 <= '0;
    end else begin
      if (i_wr_en) begin
        if (i_wr_addr != 5'b0) begin  // protect against writes to x[0]
          x[i_wr_addr-1] <= i_wr_data;
        end
      end
      rd_data1 <= i_rd_addr1 == 0 ? '0 : x[i_rd_addr1-1];
      rd_data2 <= i_rd_addr2 == 0 ? '0 : x[i_rd_addr2-1];
    end
  end

  // always_ff @(posedge clk) begin
  //   case (rd_addr1_ip)
  //     5'b0: next_rd_data1 <= {XW{1'b0}};
  //     i_wr_addr:
  //     next_rd_data1 <= i_wr_data;  // same cycle read and write supported (hazard prevention)
  //     default: next_rd_data1 <= rd_data1;
  //   endcase
  // end
  //
  // always_ff @(posedge clk) begin
  //   case (rd_addr2_ip)
  //     5'b0:       next_rd_data2 <= {XW{1'b0}};
  //     i_wr_addr: next_rd_data2 <= i_wr_data;
  //     default:    next_rd_data2 <= rd_data2;
  //   endcase
  // end

  assign o_rd_data1 = rd_data1;
  assign o_rd_data2 = rd_data2;

endmodule
