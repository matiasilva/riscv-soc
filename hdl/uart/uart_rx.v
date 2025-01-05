`include "platform.vh"
`default_nettype none

module uart_rx #(
   parameter WORD_WIDTH = 8,
   parameter OVERSAMPLING = 16,
   parameter BAUD_RATE = 115200
)(
   input wire clk,
   input wire rst_n,
   input wire din,

   // read interface
   output wire rd_valid,
   output wire [WORD_WIDTH-1:0] rd_data,
   input wire rd_ready
);

localparam DATA_WIDTH = WORD_WIDTH + 1;

// configuration
wire parity_cfg = 1'b1;
reg parity;

// configuration update
always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
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
   .clk  (clk),
   .rst_n(rst_n),
   .tick (tick)
);

uart_rx_des #( .OVERSAMPLING(OVERSAMPLING), .WORD_WIDTH(WORD_WIDTH) )
   uart_rx_des0 (
   .clk      (clk),
   .rst_n    (rst_n),
   .tick     (tick),
   .din      (din),
   .parity   (parity),
   .dout     (data),
   .frame_err(frame_err),
   .done     (des_done),
   .active   (des_active)
);

wire [WORD_WIDTH-1:0] word = parity ? data [DATA_WIDTH-2:0] : data[DATA_WIDTH-1:1];
wire flag_clear;
wire flag;
wire [WORD_WIDTH-1:0] flag_data;
wire parity_ok = data[DATA_WIDTH-1] == ~(^word);
wire flag_set = des_done && (parity ? parity_ok : 1'b1);

flag_buf #( .WORD_WIDTH(WORD_WIDTH) ) flag_buf0 (
   .clk         (clk),
   .rst_n       (rst_n),
   .flag_set    (flag_set),
   .flag_clear  (flag_clear),
   .din         (word),
   .flag        (flag),
   .dout        (flag_data),
   .overflow_err(overflow_err)
);

assign rd_valid = flag;
assign flag_clear = rd_valid && rd_ready;
assign rd_data = flag_data;

endmodule
