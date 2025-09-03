`include "platform.vh"
`default_nettype none

module uart_rx #(
   parameter WORD_WIDTH = 8,
   parameter OVERSAMPLING = 16,
   parameter BAUD_RATE = 115200
)(
   input wire i_clk,
   input wire i_rst_n,
   input wire i_din,

   // read interface
   output wire o_rd_valid,
   output wire [WORD_WIDTH-1:0] o_rd_data,
   input wire i_rd_ready
);

localparam DATA_WIDTH = WORD_WIDTH + 1;

// configuration
wire parity_cfg = 1'b1;
reg parity;

// configuration update
always @(posedge i_clk or negedge i_rst_n) begin
   if (~i_rst_n) begin
      parity <= 1'b0;
   end else begin
      if (parity != parity_cfg && !des_active)
         parity <= parity_cfg;
   end
end


wire tick;
wire des_done; // tick
wire des_active;
wire [DATA_WIDTH-1:0] data;

// errors TODO: deal with errors better
wire frame_err; // edge
wire parity_err = parity && !parity_ok; // edge
wire overflow_err; // level

baud_gen #( .OVERSAMPLING(OVERSAMPLING), .FREQ(`SYSFREQ), .BAUD_RATE(BAUD_RATE) )
   baud_gen0 (
   .i_clk  (i_clk),
   .i_rst_n(i_rst_n),
   .o_tick (tick)
);

uart_rx_des #( .OVERSAMPLING(OVERSAMPLING), .WORD_WIDTH(WORD_WIDTH) )
   uart_rx_des0 (
   .i_clk      (i_clk),
   .i_rst_n    (i_rst_n),
   .i_tick     (tick),
   .i_din      (i_din),
   .i_parity   (parity),
   .o_dout     (data),
   .o_frame_err(frame_err),
   .o_done     (des_done),
   .o_active   (des_active)
);

wire [WORD_WIDTH-1:0] word = parity ? data [DATA_WIDTH-2:0] : data[DATA_WIDTH-1:1];
wire parity_ok = data[DATA_WIDTH-1] == ~(^word);
wire flag_clear;
wire flag;
wire [WORD_WIDTH-1:0] flag_data;
wire flag_set = des_done && (parity ? parity_ok : 1'b1);

flag_buf #( .WORD_WIDTH(WORD_WIDTH) ) flag_buf0 (
   .i_clk         (i_clk),
   .i_rst_n       (i_rst_n),
   .i_flag_set    (flag_set),
   .i_flag_clear  (flag_clear),
   .i_din         (word),
   .o_flag        (flag),
   .o_dout        (flag_data),
   .o_overflow_err(overflow_err)
);

assign o_rd_valid = flag;
assign flag_clear = o_rd_valid && i_rd_ready;
assign o_rd_data = flag_data;

endmodule
