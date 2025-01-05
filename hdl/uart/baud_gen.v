`default_nettype none

module baud_gen #(
   parameter OVERSAMPLING = 16,
   parameter BAUD_RATE = 115200,
   parameter FREQ = 50000000
) (
   input wire clk,
   input wire rst_n,

   output wire tick
);

localparam OVERSAMLING_FREQ = OVERSAMPLING * BAUD_RATE;
localparam M =  (FREQ + OVERSAMLING_FREQ - 1) / OVERSAMLING_FREQ; // (A+B-1)/B rounds up after truncation
localparam N = $clog2(M);

reg [N-1:0] cnt;
wire [N-1:0] cnt_next;

always @(posedge clk or negedge rst_n)
   if (~rst_n)
      cnt <= 0;
   else
      cnt <= cnt_next;

assign cnt_next = (cnt == (M - 1)) ? 0 : cnt + 1;

assign tick = cnt == (M - 1);

endmodule
