`default_nettype none

/* one word buffer with flag */

module flag_buf #(
   parameter WORD_WIDTH = 8
) (
   input wire i_clk,
   input wire i_rst_n,

   input wire i_flag_set,
   input wire i_flag_clear,
   input wire [WORD_WIDTH-1:0] i_din,

   output reg o_flag,
   output wire [WORD_WIDTH-1:0] o_dout,
   output reg o_overflow_err
);

reg [WORD_WIDTH-1:0] data_buf;

always @(posedge i_clk or negedge i_rst_n) begin
   if (~i_rst_n) begin
      data_buf <= 0;
      o_flag <= 1'b0;
      o_overflow_err <= 1'b0;
   end else begin
      if (i_flag_set) begin
         o_flag <= 1'b1;
         data_buf <= i_din;
         if (o_flag)
            o_overflow_err <= 1'b1;
      end else if (i_flag_clear) begin
         o_overflow_err <= 1'b0;
         o_flag <= 1'b0;
      end
   end
end

assign o_dout = data_buf;

endmodule
