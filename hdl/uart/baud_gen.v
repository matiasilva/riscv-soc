`include "platform.vh"
`default_nettype none

module baud_gen #(
   parameter OVERSAMPLING = 16,
   parameter BAUD_RATE = 115200
) (
   input wire clk,
   input wire rst_n,

   output wire tick
);

localparam M = 1 + `SYSFREQ / (OVERSAMPLING * BAUD_RATE);
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
