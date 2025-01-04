`default_nettype none

module uart_rx (
   input wire clk,
   input wire rst_n,
   input wire sd
);

wire tick;

baud_gen baud_gen0 (
   .clk(clk),
   .rst_n(rst_n),
   .tick(tick)
);

endmodule
