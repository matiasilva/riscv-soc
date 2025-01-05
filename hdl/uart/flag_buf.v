`default_nettype none

module flag_buf #(
   parameter WORD_WIDTH = 8
) (
   input wire clk,
   input wire rst_n,

   input wire flag_set,
   input wire flag_clear,
   input wire [WORD_WIDTH-1:0] din,

   output reg flag,
   output wire [WORD_WIDTH-1:0] dout,
   output reg overflow_err
);

reg [WORD_WIDTH-1:0] data_buf;

always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
      data_buf <= 0;
      flag <= 1'b0;
      overflow_err <= 1'b0;
   end else begin
      if (flag_set) begin
         flag <= 1'b1;
         data_buf <= din;
         if (flag)
            overflow_err <= 1'b1;
      end else if (flag_clear) begin
         overflow_err <= 1'b0;
         flag <= 1'b0;
      end
   end
end

assign dout = data_buf;

endmodule
