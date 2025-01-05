module uart_tx (
   input wire clk,
   input wire rst_n,
   input wire tick,

   // write interface
   input wire [WORD_WIDTH-1:0] wr_data,
   input wire wr_valid,
   output wire wr_ready,

   output wire dout
);
